# Walkthrough: Relate Acceleration to Tire Force

Keep one visual transition on screen at a time.

1. Read the guiding question: What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?
2. Recall P01: tire grip bounded acceleration. Predict once what happens to `m*a` if mass doubles.
3. Run only the force-balance baseline section. Name the force unit and close the balance in newtons.
4. Advance once to the separate baseline acceleration view. Name its unit and explain why request equals realization.
5. Run Sweep 1. Increase requested acceleration while mass, speed, grip, `Crr`, and `CdA` stay fixed.
6. Observe where required force continues upward but delivered force clips at `mu*m*g`.
7. Read the first mechanism explanation, then reset every input to the baseline.
8. Run Sweep 2. Change mass only and identify which force component does not scale with mass.
9. Read the second mechanism explanation before combining any controls.
10. Run only the deliberately broken force view. Name the violated assumption: road loads were omitted.
11. Advance once to the separate acceleration view and connect the force gap to its shortfall.
12. Open `interactive.m`, select one view, move one bounded control, answer its observation question, and reset.
13. Switch views as a separate transition; do not combine another lever change with the switch.
14. At the zero-speed limiting case, name the deliberate zero-rolling convention and its boundary.
15. Run `run_checks.m` and answer the interpretation prompts in `checks.md`.
16. Give the two-sentence teach-back: mechanism first, consequence second.
17. Only after both gates pass, record progress with `./bin/learn complete P02 --checks-passed --teach-back "<your answer>"`.

Do not mark personal completion until executable checks pass and the teach-back is clear.
