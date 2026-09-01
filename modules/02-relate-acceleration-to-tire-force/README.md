# P02 — Relate Acceleration to Tire Force

**Track:** Vehicle Dynamics and Motorsport Engineering  
**Phase 1:** Motion and force  
**Status:** implemented

## Guiding question

What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?

## Physical mental model

Acceleration determines net longitudinal force through `F_net = m*a`. Once the car is moving, this
lesson approximates rolling resistance as `Crr*m*g`; at exactly zero speed it sets rolling loss to
zero rather than attempting to model tire breakaway. The tires must also overcome aerodynamic drag,
so the contact-patch request is

`F_tire,required = m*a_request + F_roll + F_drag`.

The road can deliver no more than the simplified traction limit `F_tire,limit = mu*m*g`. When the
request crosses that limit, delivered tire force plateaus and realized acceleration falls below the
request.

This level-road, straight-line aggregate model deliberately leaves axle load transfer to P03 and
combined longitudinal/lateral force to P04.

## Required learning flow

1. Read the force balance and make one prediction about doubling mass.
2. Establish a deterministic baseline, first as a force budget and then as a separate acceleration view.
3. Sweep requested acceleration while every other input stays at baseline.
4. Reset, then sweep mass independently.
5. Break the assumption that `m*a` alone equals tire force, then advance to the separate shortfall view.
6. Explain each change from the equations, then run the checks and give a teach-back.

## Implementation contract

The completed module owns these files:

- `lesson.m` — notebook-style MATLAB sections (`%%`) and concise narrative.
- `interactive.m` — `uifigure` controls, plots, and immediate feedback.
- `model.m` — deterministic calculations separated from presentation.
- `experiment.m` — reproducible baseline, sweeps, and broken case.
- `lesson.md` — tutor-facing explanation and misconceptions.
- `walkthrough.md` — expected observations in order.
- `checks.md` and `run_checks.m` — conceptual and numerical completion checks.

Prefer base MATLAB. Optional toolbox comparisons may be added only after the underlying operation is visible.

## Dependencies and evidence boundary

The implementation uses base MATLAB only and has no random, file, network, or toolbox-dependent
inputs. Inputs are bounded to finite forward-traction cases, including vehicle mass from 1 to
100000 kg. The guided experiment replaces its prior P02 window at each section, and the interactive
panel shows one selected view at a time. Repository CI checks structure and retained deterministic
contracts. MATLAB execution, UI behavior, numerical fidelity, learner efficacy, and physical
validation require separate evidence.
