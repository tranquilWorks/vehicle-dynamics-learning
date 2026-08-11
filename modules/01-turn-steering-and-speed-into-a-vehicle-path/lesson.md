# Lesson: Turn Steering and Speed into a Vehicle Path

## Guiding question

How do steering, speed, and tire grip determine the path a car can actually follow?

## Mental model

Steering asks the tires for lateral acceleration. Speed squares that demand, while friction sets the maximum force the road can supply.

## What to manipulate

Use `interactive.m`. Change one lever at a time before combining effects.

## First observation

Hold steering fixed and increase speed. The path radius remains geometrically requested, but required lateral acceleration rises as speed squared until tire friction cannot support it.

## Common mistakes

- The steering wheel does not directly command yaw rate at every speed.
- A tighter geometric path may be physically infeasible.
- More grip raises the limit; it does not change the low-speed kinematic relationship.

## Completion standard

The learner can explain the baseline, identify what each lever changes, diagnose the deliberately broken case, and pass `run_checks.m`.
