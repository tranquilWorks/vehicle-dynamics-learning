from __future__ import annotations

import json
import math
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
QUESTION = (
    "What inputs, observable effects, and failure modes matter when you relate "
    "Acceleration to Tire Force?"
)
ARTIFACTS = (
    "README.md",
    "lesson.m",
    "model.m",
    "experiment.m",
    "interactive.m",
    "lesson.md",
    "walkthrough.md",
    "checks.md",
    "run_checks.m",
)


def compact(text: str) -> str:
    return re.sub(r"\s+", "", text.replace("...", ""))


def reference_force_balance(
    accel_mps2: float,
    mass_kg: float,
    speed_mps: float,
    mu: float,
    rolling_coefficient: float,
    drag_area_m2: float,
) -> dict[str, float | bool]:
    """Independent Python mirror of the documented P02 equations, not MATLAB execution."""
    gravity = 9.80665
    air_density = 1.225
    normal_force = mass_kg * gravity
    inertial_force = mass_kg * accel_mps2
    rolling_force = 0.0 if speed_mps == 0 else rolling_coefficient * normal_force
    drag_force = 0.5 * air_density * drag_area_m2 * speed_mps**2
    road_load = rolling_force + drag_force
    required = inertial_force + road_load
    limit = mu * normal_force
    delivered = min(required, limit)
    realized = (delivered - road_load) / mass_kg
    if limit == 0:
        utilization = 0.0 if required == 0 else math.inf
    else:
        utilization = required / limit
    return {
        "normal": normal_force,
        "inertial": inertial_force,
        "rolling": rolling_force,
        "drag": drag_force,
        "road_load": road_load,
        "required": required,
        "limit": limit,
        "delivered": delivered,
        "realized": realized,
        "utilization": utilization,
        "limited": required > limit,
    }


class P02ModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(
            (ROOT / "curriculum/modules.json").read_text(encoding="utf-8")
        )
        cls.module = next(m for m in cls.manifest["modules"] if m["id"] == "P02")
        cls.folder = ROOT / cls.module["folder"]
        cls.text = {
            name: (cls.folder / name).read_text(encoding="utf-8") for name in ARTIFACTS
        }

    def test_artifact_completeness_and_permanent_manifest_identity(self):
        self.assertEqual(
            {
                "number": self.module["number"],
                "id": self.module["id"],
                "title": self.module["title"],
                "guiding_question": self.module["guiding_question"],
                "phase": self.module["phase"],
                "folder": self.module["folder"],
                "status": self.module["status"],
                "implementation_batch": self.module["implementation_batch"],
                "prerequisites": self.module["prerequisites"],
            },
            {
                "number": 2,
                "id": "P02",
                "title": "Relate Acceleration to Tire Force",
                "guiding_question": QUESTION,
                "phase": 1,
                "folder": "modules/02-relate-acceleration-to-tire-force",
                "status": "implemented",
                "implementation_batch": "P02",
                "prerequisites": ["P01"],
            },
        )
        self.assertIsInstance(self.module["evidence_level"], str)
        self.assertNotEqual(self.module["evidence_level"], "none")
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                path = self.folder / name
                self.assertTrue(path.is_file())
                self.assertTrue(self.text[name].strip())
        self.assertIn("**Status:** implemented", self.text["README.md"])

    def test_changed_module_text_has_exactly_one_terminal_newline(self):
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                payload = (self.folder / name).read_bytes()
                self.assertTrue(payload.endswith(b"\n"))
                self.assertFalse(payload.endswith(b"\n\n"))

    def test_deterministic_model_and_limiting_case_contracts_are_transparent(self):
        source = self.text["model.m"]
        normalized = compact(source)
        equations = (
            "normalForce=massKg*g;",
            "inertialForce=massKg*accelRequestMps2;",
            "rollingForce=rollingCoefficient*normalForce;",
            "aerodynamicDragForce=0.5*airDensity*dragAreaM2*speedMps^2;",
            "roadLoadForce=rollingForce+aerodynamicDragForce;",
            "requiredTireForce=inertialForce+roadLoadForce;",
            "tractionLimit=mu*normalForce;",
            "deliveredTireForce=min(requiredTireForce,tractionLimit);",
            "realizedAccelMps2=netForce/massKg;",
        )
        for equation in equations:
            with self.subTest(equation=equation):
                self.assertIn(equation, normalized)
        self.assertEqual(source.count("= double("), 6)
        self.assertIn("massKg < 1 || massKg > 1e5", source)

        prohibited = re.compile(
            r"\b(?:figure|plot|uifigure|rand|rng|load|save|readtable|webread|"
            r"urlread|fmincon|sim)\s*\(|^\s*(?:global|persistent)\b",
            re.IGNORECASE | re.MULTILINE,
        )
        self.assertIsNone(prohibited.search(source))

        baseline = reference_force_balance(3, 1500, 20, 0.8, 0.015, 0.65)
        repeated = reference_force_balance(3, 1500, 20, 0.8, 0.015, 0.65)
        self.assertEqual(baseline, repeated)
        self.assertTrue(math.isclose(baseline["inertial"], 4500.0, abs_tol=1e-12))
        self.assertTrue(math.isclose(baseline["rolling"], 220.649625, abs_tol=1e-9))
        self.assertTrue(math.isclose(baseline["drag"], 159.25, abs_tol=1e-12))
        self.assertTrue(math.isclose(baseline["required"], 4879.899625, abs_tol=1e-9))
        self.assertTrue(math.isclose(baseline["limit"], 11767.98, abs_tol=1e-9))
        self.assertTrue(math.isclose(baseline["realized"], 3.0, abs_tol=1e-12))
        self.assertFalse(baseline["limited"])

        stationary = reference_force_balance(0, 1500, 0, 0.8, 0.015, 0.65)
        self.assertEqual(stationary["rolling"], 0.0)
        self.assertEqual(stationary["drag"], 0.0)
        self.assertEqual(stationary["required"], 0.0)
        no_grip = reference_force_balance(3, 1500, 20, 0, 0.015, 0.65)
        self.assertEqual(no_grip["delivered"], 0.0)
        self.assertLess(no_grip["realized"], 0.0)
        self.assertTrue(math.isinf(no_grip["utilization"]))

    def test_two_independent_sweeps_and_broken_case_are_regression_locked(self):
        source = self.text["experiment.m"]
        normalized = compact(source)
        ordered_sections = (
            "%% Read and make one prediction",
            "%% Baseline",
            "%% Baseline changed view",
            "%% Sweep 1",
            "%% Explain the first changed view",
            "%% Sweep 2",
            "%% Explain the second changed view",
            "%% Broken case",
            "%% Broken case changed view",
            "%% Check before teach-back",
        )
        positions = [source.index(section) for section in ordered_sections]
        self.assertEqual(positions, sorted(positions))
        read_section = source[positions[0] : positions[1]]
        for setup in (
            "clear model;",
            "modelFcn = @model;",
            "baselineAccelMps2 = 3;",
            "baselineMassKg = 1500;",
            "baselineSpeedMps = 20;",
            "baselineMu = 0.8;",
            "baselineCrr = 0.015;",
            "baselineCdAM2 = 0.65;",
        ):
            with self.subTest(read_section_setup=setup):
                self.assertIn(setup, read_section)
        self.assertEqual(source.lower().count("disp('prediction:"), 1)
        self.assertIn("accelSweepMps2=[02468];", normalized)
        self.assertIn("massSweepKg=[9001200150018002100];", normalized)
        self.assertIn(
            "sample=modelFcn(accelSweepMps2(k),baselineMassKg,baselineSpeedMps,"
            "baselineMu,baselineCrr,baselineCdAM2);",
            normalized,
        )
        self.assertIn(
            "sample=modelFcn(baselineAccelMps2,massSweepKg(k),baselineSpeedMps,"
            "baselineMu,baselineCrr,baselineCdAM2);",
            normalized,
        )
        self.assertIn("brokenSpeedMps=40;", normalized)
        self.assertIn("naiveTireForceN=broken.massKg*broken.accelRequestMps2;", normalized)
        self.assertIn("forceBalanceGapN=broken.requiredTireForce-naiveTireForceN;", normalized)
        self.assertGreaterEqual(source.count("fprintf("), 6)
        for label in (
            "Longitudinal force (kN)",
            "Acceleration (m/s^2)",
            "Requested acceleration (m/s^2)",
            "Vehicle mass (kg)",
            "Tire force (kN)",
        ):
            self.assertIn(label, source)
        for tag in (
            "P02BaselineForceBalance",
            "P02BaselineAcceleration",
            "P02AccelerationSweep",
            "P02MassSweep",
            "P02BrokenRoadLoad",
            "P02BrokenAcceleration",
        ):
            self.assertEqual(source.count(tag), 1)
        self.assertNotIn("subplot(", source)
        self.assertIn("'Tag','P02Experiment'", compact(source))
        self.assertIn("'UserData',identifierValue", compact(source))
        self.assertIn("'Tag','P02Interactive'", compact(source))

        low_accel = reference_force_balance(2, 1500, 20, 0.8, 0.015, 0.65)
        high_accel = reference_force_balance(4, 1500, 20, 0.8, 0.015, 0.65)
        self.assertTrue(
            math.isclose(
                high_accel["required"] - low_accel["required"],
                1500 * 2,
                abs_tol=1e-9,
            )
        )
        light = reference_force_balance(3, 900, 20, 0.8, 0.015, 0.65)
        heavy = reference_force_balance(3, 2100, 20, 0.8, 0.015, 0.65)
        self.assertTrue(math.isclose(light["drag"], heavy["drag"], abs_tol=1e-12))
        broken = reference_force_balance(3, 1500, 40, 0.8, 0.015, 0.65)
        naive_force = 1500 * 3
        self.assertTrue(
            math.isclose(broken["required"] - naive_force, broken["road_load"], abs_tol=1e-9)
        )
        self.assertLess(naive_force, broken["limit"])

    def test_malformed_recovery_isolation_and_resource_checks_are_executable(self):
        source = self.text["run_checks.m"]
        required_markers = (
            "defaultBaseline = modelFcn();",
            "expectedInertiaN",
            "expectedRollingN",
            "expectedDragN",
            "accelSweepMps2",
            "massSweepKg",
            "zeroRequest",
            "stationary",
            "lowGrip",
            "noGrip",
            "zeroEverything",
            "bounded = modelFcn(20,1e5,120,3,0.1,5);",
            "lowerMassBound = modelFcn(0,1,0,0,0,0);",
            "integerBaseline",
            "invalidCases",
            "recovered",
            "afterErrors",
            "mutatedCopy",
            "P02 checks passed.",
        )
        for marker in required_markers:
            with self.subTest(marker=marker):
                self.assertIn(marker, source)
        self.assertGreaterEqual(source.count("assert("), 30)
        self.assertGreaterEqual(source.count("@() modelFcn"), 22)
        for error_id in (
            "P02:model:InvalidInput",
            "P02:model:AccelerationOutOfRange",
            "P02:model:MassOutOfRange",
            "P02:model:SpeedOutOfRange",
            "P02:model:GripOutOfRange",
            "P02:model:RollingOutOfRange",
            "P02:model:DragAreaOutOfRange",
        ):
            self.assertIn(error_id, source)
        normalized = compact(source)
        self.assertIn("fork=1:size(invalidCases,1)", normalized)
        self.assertIn(
            "assertRejects(invalidCases{k,1},invalidCases{k,2}", normalized
        )
        self.assertIn("recovered=modelFcn(3,1500,20,0.8,0.015,0.65);", normalized)
        self.assertIn("assert(isequaln(baseline,recovered)", normalized)
        self.assertIn("afterErrors=modelFcn(3,1500,20,0.8,0.015,0.65);", normalized)
        self.assertIn("assert(isequaln(baseline,afterErrors)", normalized)
        self.assertIn("afterMutation=modelFcn(3,1500,20,0.8,0.015,0.65);", normalized)

    def test_interactive_controls_are_meaningful_bounded_and_isolated(self):
        source = self.text["interactive.m"]
        normalized = compact(source)
        self.assertEqual(source.count("uislider("), 6)
        for control in (
            "Acceleration (m/s^2)",
            "Mass (kg)",
            "Speed (m/s)",
            "Grip mu (-)",
            "Rolling Crr (-)",
            "Drag area CdA (m^2)",
        ):
            self.assertIn(control, source)
        for limits in (
            "'Limits',[010]",
            "'Limits',[8002500]",
            "'Limits',[070]",
            "'Limits',[0.11.5]",
            "'Limits',[00.04]",
            "'Limits',[0.31.2]",
        ):
            self.assertIn(limits, normalized)
        self.assertIn("'Tag','P02Interactive'", normalized)
        self.assertIn("'Tag','P02Experiment'", normalized)
        self.assertIn("delete(existing);", source)
        self.assertIn("delete(guided);", source)
        self.assertEqual(source.count("uiaxes("), 1)
        self.assertEqual(source.count("uidropdown("), 1)
        self.assertIn("{'Force balance','Demand curve'}", source)
        self.assertNotIn("ValueChangingFcn", source)
        self.assertIn("cla(axView,'reset');", source)
        self.assertIn("select one view", source.lower())
        self.assertIn("curveAccelMps2 = linspace(0,10,101);", source)
        self.assertIn("Reset baseline", source)
        self.assertIn("which equation term moved first", source)
        self.assertNotRegex(source.lower(), r"\b(?:sim|fmincon|fit|predict)\s*\(")

    def test_tutor_material_is_concept_first_complete_and_not_placeholder_text(self):
        lesson_script = self.text["lesson.m"]
        lesson = self.text["lesson.md"]
        walkthrough = self.text["walkthrough.md"]
        checks = self.text["checks.md"]
        readme = self.text["README.md"]
        for name in ("README.md", "lesson.m", "lesson.md", "walkthrough.md"):
            self.assertIn(QUESTION, self.text[name])
        self.assertIn("P01", lesson_script)
        self.assertIn("Connection to P01", lesson)
        self.assertIn("mechanism", lesson.lower())
        self.assertIn("Common mistakes", lesson)
        self.assertNotRegex(lesson_script, r"(?m)^\s*(?:experiment|interactive)\s*;\s*$")
        self.assertIn('run_module_checks("P02")', lesson_script)
        self.assertIn("one visual transition", walkthrough.lower())
        self.assertIn("Interpretation", checks)
        self.assertIn("Teach-back", checks)
        self.assertIn("F_roll = 0", lesson)
        normalized_readme = re.sub(r"\s+", " ", readme)
        self.assertIn("MATLAB execution", normalized_readme)
        self.assertIn("physical validation", normalized_readme)

        placeholder = re.compile(
            r"\b(?:todo|tbd|placeholder|not implemented|activate its governed implementation batch)\b",
            re.IGNORECASE,
        )
        for name, text in self.text.items():
            with self.subTest(artifact=name):
                self.assertIsNone(placeholder.search(text))


if __name__ == "__main__":
    unittest.main()
