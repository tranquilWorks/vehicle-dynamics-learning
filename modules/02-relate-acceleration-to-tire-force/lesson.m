%% P02 - Relate Acceleration to Tire Force
% Guiding question:
% What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?
%
% P01 showed that acceleration demands must remain inside tire grip. P02
% now exposes the longitudinal force balance behind that limit.

%% Read the mechanism before MATLAB syntax
disp('Acceleration fixes net force m*a. Tire force must also overcome rolling and aerodynamic loads.');
disp('Available aggregate traction is bounded here by mu*m*g.');

%% Make one prediction, then reveal only the first baseline view
% Open experiment.m in the MATLAB Editor. Run its Read section, answer the
% one prediction, and then run only the force-balance Baseline section.
disp('Next: open experiment.m and run Read, then the force-balance Baseline. Stop after that view.');

%% Advance one controlled transition at a time
% Advance to the separate baseline acceleration view, then Sweep 1 and its
% explanation. Reset before Sweep 2. The broken force and symptom views are
% also separate sections.
disp('Advance one section at a time; reset before Sweep 2 and stop at each changed view.');

%% Open the bounded lever panel after the guided experiment
% Run interactive.m only after the guided sections. Select one view, change
% one control, explain its first changed equation term, and use Reset baseline.
disp('After the broken case, run interactive; select one view and move one bounded control.');

%% Check and teach back
% Run run_module_checks("P02"), then explain: mechanism first, observable
% consequence second. Do not record learner completion before both pass.
