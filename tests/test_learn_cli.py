from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


class LearnCliTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "curriculum/modules.json").read_text(encoding="utf-8"))

    def create_fixture(self, temporary: str) -> Path:
        fixture = Path(temporary) / "repo"
        shutil.copytree(ROOT / "bin", fixture / "bin")
        shutil.copytree(ROOT / "curriculum", fixture / "curriculum")
        manifest = json.loads((fixture / "curriculum/modules.json").read_text(encoding="utf-8"))
        for module in manifest["modules"]:
            source = ROOT / module["folder"]
            target = fixture / module["folder"]
            target.mkdir(parents=True, exist_ok=True)
            for name in ("README.md", "lesson.md", "walkthrough.md", "checks.md", "run_checks.m"):
                path = source / name
                if path.exists():
                    shutil.copy2(path, target / name)
        return fixture

    def force_fixture_scaffold(self, fixture: Path) -> dict:
        manifest_path = fixture / "curriculum/modules.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        module = next(m for m in reversed(manifest["modules"]) if m["id"] != "P02")
        module["status"] = "scaffolded"
        module["evidence_level"] = "none"
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        return module

    def load_cli_module(self, fixture: Path):
        module_path = fixture / "bin/learn.py"
        specification = importlib.util.spec_from_file_location(
            f"fixture_learn_{id(fixture)}", module_path
        )
        self.assertIsNotNone(specification)
        self.assertIsNotNone(specification.loader)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        return module

    def run_cli_in(self, fixture: Path, *args: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        return subprocess.run(
            [str(fixture / "bin/learn"), *args],
            cwd=fixture,
            text=True,
            capture_output=True,
            env=environment,
            timeout=10,
        )

    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as temporary:
            return self.run_cli_in(self.create_fixture(temporary), *args)

    def complete_module(self, fixture: Path, module_id: str) -> None:
        completed = self.run_cli_in(
            fixture,
            "complete",
            module_id,
            "--checks-passed",
            "--teach-back",
            "Mechanism first; observable consequence second.",
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_status_and_list(self):
        status = self.run_cli("status")
        self.assertEqual(status.returncode, 0, status.stderr)
        implemented = sum(m["status"] == "implemented" for m in self.manifest["modules"])
        self.assertIn(
            f"{self.manifest['module_count']} total, {implemented} implemented",
            status.stdout,
        )
        listing = self.run_cli("list")
        self.assertEqual(listing.returncode, 0, listing.stderr)
        self.assertEqual(
            len([line for line in listing.stdout.splitlines() if line.strip()]),
            self.manifest["module_count"],
        )

    def test_status_counts_only_true_known_completion_entries(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            state_path.write_text(
                json.dumps(
                    {
                        "current": "P01",
                        "completed": {"P01": False, "P99": True},
                        "notes": {},
                    },
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            status = self.run_cli_in(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("0 completed", status.stdout)

    def test_reference_starts_and_controlled_scaffold_refuses(self):
        reference = self.run_cli("start", "P01")
        self.assertEqual(reference.returncode, 0, reference.stderr)
        self.assertIn("Guiding question:", reference.stdout)

        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            scaffold_module = self.force_fixture_scaffold(fixture)
            scaffold = self.run_cli_in(fixture, "start", scaffold_module["id"])
            self.assertEqual(scaffold.returncode, 2)
            self.assertIn("Activate its governed implementation batch", scaffold.stdout)

    def test_p02_starts_as_an_implemented_module(self):
        p02 = next(m for m in self.manifest["modules"] if m["id"] == "P02")
        self.assertEqual(p02["status"], "implemented")
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            self.complete_module(fixture, "P01")
            started = self.run_cli_in(fixture, "start", "P02")
            self.assertEqual(started.returncode, 0, started.stderr)
            self.assertIn(p02["guiding_question"], started.stdout)
            checked = self.run_cli_in(fixture, "check", "P02")
            self.assertEqual(checked.returncode, 0, checked.stderr)
            self.assertIn("run_module_checks('P02')", checked.stdout)

    def test_p02_prerequisite_blocks_start_and_completion_without_state_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            state_path = fixture / ".learning/progress.json"

            blocked_start = self.run_cli_in(fixture, "start", "P02")
            self.assertEqual(blocked_start.returncode, 2)
            self.assertIn("Complete prerequisite(s): P01", blocked_start.stdout)
            self.assertFalse(state_path.exists())

            blocked_completion = self.run_cli_in(
                fixture,
                "complete",
                "P02",
                "--checks-passed",
                "--teach-back",
                "Tire force supplies net acceleration plus road loads; grip clips delivery.",
            )
            self.assertEqual(blocked_completion.returncode, 2)
            self.assertIn("Complete prerequisite(s): P01", blocked_completion.stdout)
            self.assertFalse(state_path.exists())

            self.complete_module(fixture, "P01")
            started = self.run_cli_in(fixture, "start", "P02")
            self.assertEqual(started.returncode, 0, started.stderr)
            self.assertTrue(started.stdout.startswith("P02 —"), started.stdout)

    def test_rejected_scaffold_start_preserves_current_implemented_module(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            scaffold = self.force_fixture_scaffold(fixture)
            self.complete_module(fixture, "P01")
            started = self.run_cli_in(fixture, "start", "P02")
            self.assertEqual(started.returncode, 0, started.stderr)

            rejected = self.run_cli_in(fixture, "start", scaffold["id"])
            self.assertEqual(rejected.returncode, 2)

            continued = self.run_cli_in(fixture, "continue")
            self.assertEqual(continued.returncode, 0, continued.stderr)
            self.assertTrue(continued.stdout.startswith("P02 —"), continued.stdout)

    def test_completion_requires_checks_and_teach_back_before_state_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            state_path = fixture / ".learning/progress.json"
            self.complete_module(fixture, "P01")
            original = state_path.read_bytes()

            missing_checks = self.run_cli_in(fixture, "complete", "P02")
            self.assertEqual(missing_checks.returncode, 2)
            self.assertIn("run_module_checks('P02')", missing_checks.stdout)
            self.assertEqual(state_path.read_bytes(), original)

            missing_teach_back = self.run_cli_in(
                fixture, "complete", "P02", "--checks-passed"
            )
            self.assertEqual(missing_teach_back.returncode, 2)
            self.assertIn("--teach-back", missing_teach_back.stdout)
            self.assertEqual(state_path.read_bytes(), original)

            completed = self.run_cli_in(
                fixture,
                "complete",
                "P02",
                "--checks-passed",
                "--teach-back",
                "Tire force supplies net acceleration plus road loads; grip clips delivery.",
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertTrue(state["completed"]["P02"])
            self.assertEqual(state["current"], "P02")
            self.assertIn("Teach-back:", state["notes"]["P02"])

    def test_malformed_state_is_preserved_and_manual_recovery_succeeds(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = self.create_fixture(temporary)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            malformed = b'{"current": "P02",'
            state_path.write_bytes(malformed)

            rejected = self.run_cli_in(fixture, "start", "P02")
            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn("no learner data was changed", rejected.stderr.lower())
            self.assertEqual(state_path.read_bytes(), malformed)

            state_path.write_text(
                json.dumps(
                    {"current": "P02", "completed": {"P01": True}, "notes": {}},
                    indent=2,
                )
                + "\n",
                encoding="utf-8",
            )
            recovered = self.run_cli_in(fixture, "continue")
            self.assertEqual(recovered.returncode, 0, recovered.stderr)
            self.assertTrue(recovered.stdout.startswith("P02 —"), recovered.stdout)

    def test_failed_or_cancelled_atomic_replace_preserves_previous_progress(self):
        failures = (OSError("injected failure"), KeyboardInterrupt())
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                with tempfile.TemporaryDirectory() as temporary:
                    fixture = self.create_fixture(temporary)
                    started = self.run_cli_in(fixture, "start", "P01")
                    self.assertEqual(started.returncode, 0, started.stderr)
                    state_path = fixture / ".learning/progress.json"
                    original = state_path.read_bytes()
                    module = self.load_cli_module(fixture)
                    replacement = {"current": "P02", "completed": {}, "notes": {}}

                    with mock.patch.object(module.os, "replace", side_effect=failure):
                        with self.assertRaises(type(failure)):
                            module.save_state(replacement)

                    self.assertEqual(state_path.read_bytes(), original)
                    self.assertEqual(
                        [path.name for path in state_path.parent.iterdir()],
                        ["progress.json"],
                    )


if __name__ == "__main__":
    unittest.main()
