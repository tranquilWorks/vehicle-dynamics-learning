# Lesson: Relate Acceleration to Tire Force

## Guiding question

What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?

## Connection to P01

P01 showed that a requested acceleration can exceed `mu*g`. P02 opens that statement into forces:
multiply acceleration by mass to obtain net force, add the forces that oppose motion, and compare
the resulting tire-force request with `mu*m*g`.

## Mental model

For straight-line forward traction on a level road,

`F_inertia = m*a_request`

`F_roll = 0` at `v = 0`; otherwise `F_roll = Crr*m*g`

`F_road = F_roll + 0.5*rho*CdA*v^2`

`F_tire,required = F_inertia + F_road`

`F_tire,delivered = min(F_tire,required, mu*m*g)`

`a_realized = (F_tire,delivered - F_road)/m`

The mechanism is a force balance: the first equation describes net-force demand, while the contact
patch must supply that demand plus road loads without exceeding available grip. Tire force does not
automatically equal `m*a`.

## Observe one transition at a time

1. Before the baseline, predict what happens to `m*a` if mass doubles at fixed acceleration.
2. Read only the baseline force budget. Ask: which bars add to the delivered tire force?
3. Advance to the separate baseline acceleration view. Ask: why do request and realization agree?
4. Increase requested acceleration only. Ask: where does delivered force stop following demand?
5. Reset, then increase mass only. Ask: which terms scale with mass and which one does not?
6. Inspect the high-speed broken force view. Ask: what named forces were omitted?
7. Advance to its separate acceleration view. Ask: why does that omission create this shortfall?
8. In `interactive.m`, select one view before moving one control; explain only that transition.

## Assumptions and boundaries

- The road is level and the car is moving forward in a straight line.
- Total normal force is `m*g`; P03 adds longitudinal load transfer between axles.
- Longitudinal grip is not shared with cornering; P04 adds combined-force use.
- `Crr` and `CdA` are fixed aggregate coefficients, not tire or aero identification models.
- At exactly zero speed, rolling force is set to zero; tire breakaway and the discontinuity near
  rest are outside this controlled lesson.
- Braking, wheel slip, gearing, thermal effects, and transient driveline behavior are outside this lesson.

## Common mistakes

- `m*a` is net force, not automatically the contact-patch tire force.
- More mass raises force demand; in this aggregate idealization it also raises `mu*m*g`.
- A smooth force curve can still be wrong if acceleration units or road loads are omitted.
- A requested acceleration is not guaranteed merely because it was entered into the model.

## Completion standard

The learner can close the force balance in newtons, explain both independent sweeps, diagnose the
broken assumption from its acceleration shortfall, pass `run_checks.m`, and give the two-sentence
teach-back in `checks.md`.
