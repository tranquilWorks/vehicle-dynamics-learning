# Curriculum readiness audit

**Track:** Vehicle Dynamics and Motorsport Engineering

## Baseline conclusion

The repository has 24 uniquely identified modules in a six-phase, prerequisite-ordered sequence. P01 is the complete reference slice; P02-P24 are explicit non-runnable batch scaffolds. The learner flow is read → visualize → move one lever → visualize the delta → read/explain, followed by a broken case, checks, and teach-back.

Static structure and CLI behavior are verified in CI. MATLAB was not available during the 2026-08-11 baseline audit, so numerical execution, UI behavior, and instructional efficacy remain named validation gaps rather than implied evidence.

## Coverage and compounding order

### Phase 1: Motion and force

- **P01 — Turn Steering and Speed into a Vehicle Path:** How do steering, speed, and tire grip determine the path a car can actually follow?
- **P02 — Relate Acceleration to Tire Force:** What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?
- **P03 — See Longitudinal Weight Transfer:** What inputs, observable effects, and failure modes matter when you see Longitudinal Weight Transfer?
- **P04 — Use the Friction Circle:** What inputs, observable effects, and failure modes matter when you use the Friction Circle?

### Phase 2: Tires and handling

- **P05 — Build Slip-Ratio Intuition:** What inputs, observable effects, and failure modes matter when you build Slip-Ratio Intuition?
- **P06 — Build Slip-Angle Intuition:** What inputs, observable effects, and failure modes matter when you build Slip-Angle Intuition?
- **P07 — Use the Bicycle Model:** What inputs, observable effects, and failure modes matter when you use the Bicycle Model?
- **P08 — Separate Understeer from Oversteer:** What inputs, observable effects, and failure modes matter when you separate Understeer from Oversteer?

### Phase 3: Suspension and chassis

- **P09 — Choose Spring Rate and Ride Frequency:** What inputs, observable effects, and failure modes matter when you choose Spring Rate and Ride Frequency?
- **P10 — See Damping Change Transient Motion:** What inputs, observable effects, and failure modes matter when you see Damping Change Transient Motion?
- **P11 — Distribute Roll Stiffness:** What inputs, observable effects, and failure modes matter when you distribute Roll Stiffness?
- **P12 — Explore Camber and Toe Geometry:** What inputs, observable effects, and failure modes matter when you explore Camber and Toe Geometry?

### Phase 4: Powertrain, brakes, and aero

- **P13 — Map Engine Torque through Gearing:** What inputs, observable effects, and failure modes matter when you map Engine Torque through Gearing?
- **P14 — Choose Shift Points:** What inputs, observable effects, and failure modes matter when you choose Shift Points?
- **P15 — Model Braking Distance and Heat:** What inputs, observable effects, and failure modes matter when you model Braking Distance and Heat?
- **P16 — Balance Drag and Downforce:** What inputs, observable effects, and failure modes matter when you balance Drag and Downforce?

### Phase 5: Telemetry and identification

- **P17 — Decode and Plot CAN Signals:** What inputs, observable effects, and failure modes matter when you decode and Plot CAN Signals?
- **P18 — Fuse GPS and IMU Motion:** What inputs, observable effects, and failure modes matter when you fuse GPS and IMU Motion?
- **P19 — Estimate Vehicle State:** What inputs, observable effects, and failure modes matter when you estimate Vehicle State?
- **P20 — Identify Parameters from a Real Drive:** What inputs, observable effects, and failure modes matter when you identify Parameters from a Real Drive?

### Phase 6: Performance engineering

- **P21 — Optimize a Racing Line:** What inputs, observable effects, and failure modes matter when you optimize a Racing Line?
- **P22 — Build a Lap-Time Simulator:** What inputs, observable effects, and failure modes matter when you build a Lap-Time Simulator?
- **P23 — Compare Setup Changes Quantitatively:** What inputs, observable effects, and failure modes matter when you compare Setup Changes Quantitatively?
- **P24 — Construct a GR86 Digital Twin:** What inputs, observable effects, and failure modes matter when you construct a GR86 Digital Twin?

## Batch readiness gates

A scaffold may become `implemented` only when it has a deterministic model, a sectioned experiment, two independent parameter sweeps, one deliberately broken case, interactive controls, interpretation-focused tutor text, numerical checks, focused static tests, and evidence that says exactly what did and did not run.
