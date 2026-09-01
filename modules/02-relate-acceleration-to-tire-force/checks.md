# Checks: Relate Acceleration to Tire Force

## Executable check

Run from this module folder, or use `run_module_checks("P02")` from the repository root:

```matlab
run_checks
```

The checks independently cover the baseline arithmetic, force-balance closure, acceleration and
mass lever effects, zero-load limits, grip saturation, malformed inputs, repeatability, and the
broken road-load assumption.

## Interpretation checks

### Observation

At fixed mass, why is the slope of required tire force versus requested acceleration equal to mass?
Identify the point where delivered force stops following that line and explain why.

### Independent lever

After resetting acceleration, increase mass. Which terms scale with mass? Why does aerodynamic drag
stay fixed in this sweep?

### Limiting cases

Explain the results for zero speed, zero requested acceleration, and zero grip. At exactly zero speed,
name the model's deliberate `F_roll = 0` convention and the omitted breakaway behavior. Use force
directions and units rather than saying only that the output is small or large.

### Broken case

The broken case uses `F_tire = m*a` at high speed. Name the violated assumption, identify the omitted
force terms, and connect their sum in newtons to the acceleration shortfall in `m/s^2`.

## Teach-back

In two sentences, answer: “What inputs, observable effects, and failure modes matter when you relate
Acceleration to Tire Force?” Sentence one must state the mechanism; sentence two must state the
observable consequence of exceeding grip or omitting a force.

Only after the executable checks pass and the tutor accepts that answer, record local progress with
`./bin/learn complete P02 --checks-passed --teach-back "<your two sentences>"` from the repository root.
