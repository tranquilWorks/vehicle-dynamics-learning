%% P01 - Turn Steering and Speed into a Vehicle Path
% Guiding question:
% How do steering, speed, and tire grip determine the path a car can actually follow?
%
% Mental model:
% Steering asks the tires for lateral acceleration. Speed squares that demand, while friction sets the maximum force the road can supply.

%% Read the baseline lesson
disp('How do steering, speed, and tire grip determine the path a car can actually follow?');
disp('Steering asks the tires for lateral acceleration. Speed squares that demand, while friction sets the maximum force the road can supply.');

%% Run the deterministic experiment
experiment;

%% Open the live lever panel
% Move one control at a time and connect the visible change to the model.
interactive;
