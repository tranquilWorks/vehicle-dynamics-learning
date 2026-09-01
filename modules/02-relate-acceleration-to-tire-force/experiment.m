%% P02 - Relate Acceleration to Tire Force
% Guiding question:
% What inputs, observable effects, and failure modes matter when you relate Acceleration to Tire Force?

%% Read and make one prediction
% Net force is m*a, but the tires must also overcome rolling resistance and
% aerodynamic drag. Before plotting: at the same requested acceleration,
% what happens to the inertial-force part when vehicle mass doubles?
clear model;
modelFcn = @model;
baselineAccelMps2 = 3;
baselineMassKg = 1500;
baselineSpeedMps = 20;
baselineMu = 0.8;
baselineCrr = 0.015;
baselineCdAM2 = 0.65;
disp('Prediction: at the same acceleration, what happens to m*a when mass doubles?');

%% Baseline - inspect the force balance
baseline = modelFcn(baselineAccelMps2,baselineMassKg,baselineSpeedMps, ...
    baselineMu,baselineCrr,baselineCdAM2);
p02Figure('P02BaselineForceBalance','P02 baseline force balance');
bar([baseline.deliveredTireForce,-baseline.rollingForce, ...
    -baseline.aerodynamicDragForce,baseline.netForce]/1000);
xticks(1:4); xticklabels({'Tire','Rolling','Aero','Net'});
yline(0,'k-'); grid on;
ylabel('Longitudinal force (kN)');
title('Delivered force minus road loads');
fprintf(['Baseline force budget: mass %.0f kg, speed %.1f m/s, required %.3f kN, ' ...
    'delivered %.3f kN, limit %.3f kN.\n'],baseline.massKg,baseline.speedMps, ...
    baseline.requiredTireForce/1000,baseline.deliveredTireForce/1000, ...
    baseline.tractionLimit/1000);

%% Baseline changed view - connect the same forces to acceleration
p02Figure('P02BaselineAcceleration','P02 baseline acceleration');
bar([baseline.accelRequestMps2,baseline.realizedAccelMps2]);
xticks(1:2); xticklabels({'Requested','Realized'});
grid on; ylabel('Acceleration (m/s^2)');
title('Baseline request is feasible');
fprintf(['Same baseline: requested %.3f m/s^2, realized %.3f m/s^2, ' ...
    'traction utilization %.1f%%.\n'],baseline.accelRequestMps2, ...
    baseline.realizedAccelMps2,100*baseline.utilization);

%% Sweep 1 - requested acceleration, with mass and road loads fixed
accelSweepMps2 = [0 2 4 6 8];
requiredSweepN = zeros(size(accelSweepMps2));
deliveredSweepN = zeros(size(accelSweepMps2));
realizedSweepMps2 = zeros(size(accelSweepMps2));
accelLimited = false(size(accelSweepMps2));
for k = 1:numel(accelSweepMps2)
    sample = modelFcn(accelSweepMps2(k),baselineMassKg,baselineSpeedMps, ...
        baselineMu,baselineCrr,baselineCdAM2);
    requiredSweepN(k) = sample.requiredTireForce;
    deliveredSweepN(k) = sample.deliveredTireForce;
    realizedSweepMps2(k) = sample.realizedAccelMps2;
    accelLimited(k) = sample.tractionLimited;
end
p02Figure('P02AccelerationSweep','P02 acceleration sweep');
plot(accelSweepMps2,requiredSweepN/1000,'o-','LineWidth',1.3, ...
    'DisplayName','Required tire force');
hold on;
plot(accelSweepMps2,deliveredSweepN/1000,'s-','LineWidth',1.3, ...
    'DisplayName','Delivered tire force');
yline(baseline.tractionLimit/1000,'--','Grip limit');
hold off; grid on;
xlabel('Requested acceleration (m/s^2)'); ylabel('Tire force (kN)');
title('Lever 1: force rises with acceleration, then clips');
legend('Location','best');
fprintf('Acceleration sweep (mass, speed, grip, Crr, and CdA fixed):\n');
fprintf('  request m/s^2 | required kN | delivered kN | realized m/s^2\n');
for k = 1:numel(accelSweepMps2)
    fprintf('  %13.1f | %11.3f | %12.3f | %14.3f\n',accelSweepMps2(k), ...
        requiredSweepN(k)/1000,deliveredSweepN(k)/1000,realizedSweepMps2(k));
end

%% Explain the first changed view
% Below the limit, each 1 m/s^2 adds massKg newtons to the request. Above
% the limit, force cannot follow the request, so realized acceleration lags.
disp('Mechanism: the unsaturated force-curve slope is vehicle mass in kg.');

%% Sweep 2 - reset acceleration, then change mass independently
massSweepKg = [900 1200 1500 1800 2100];
massRequiredN = zeros(size(massSweepKg));
massLimitN = zeros(size(massSweepKg));
massDragN = zeros(size(massSweepKg));
massLimited = false(size(massSweepKg));
for k = 1:numel(massSweepKg)
    sample = modelFcn(baselineAccelMps2,massSweepKg(k),baselineSpeedMps, ...
        baselineMu,baselineCrr,baselineCdAM2);
    massRequiredN(k) = sample.requiredTireForce;
    massLimitN(k) = sample.tractionLimit;
    massDragN(k) = sample.aerodynamicDragForce;
    massLimited(k) = sample.tractionLimited;
end
p02Figure('P02MassSweep','P02 mass sweep');
plot(massSweepKg,massRequiredN/1000,'o-','LineWidth',1.3, ...
    'DisplayName','Required tire force');
hold on;
plot(massSweepKg,massLimitN/1000,'s--','LineWidth',1.3, ...
    'DisplayName','Grip limit');
hold off; grid on;
xlabel('Vehicle mass (kg)'); ylabel('Force (kN)');
title('Lever 2: mass scales inertia, rolling load, and grip');
legend('Location','best');
fprintf('Mass sweep (acceleration reset; speed, grip, Crr, and CdA fixed):\n');
fprintf('  mass kg | required kN | grip limit kN | aero drag N\n');
for k = 1:numel(massSweepKg)
    fprintf('  %7.0f | %11.3f | %13.3f | %11.1f\n',massSweepKg(k), ...
        massRequiredN(k)/1000,massLimitN(k)/1000,massDragN(k));
end

%% Explain the second changed view
% Mass changes m*a, rolling resistance, and mu*m*g together. Aerodynamic
% drag stays fixed here because speed and drag area were reset to baseline.
disp('Mechanism: mass scales several force terms, while fixed-speed aero drag does not.');

%% Broken case - pretend tire force equals m*a at high speed
brokenSpeedMps = 40;
broken = modelFcn(baselineAccelMps2,baselineMassKg,brokenSpeedMps, ...
    baselineMu,baselineCrr,baselineCdAM2);
naiveTireForceN = broken.massKg*broken.accelRequestMps2;
naiveRealizedAccelMps2 = (naiveTireForceN-broken.roadLoadForce)/broken.massKg;
forceBalanceGapN = broken.requiredTireForce-naiveTireForceN;
p02Figure('P02BrokenRoadLoad','P02 broken road-load assumption');
bar([broken.requiredTireForce,naiveTireForceN]/1000);
xticks(1:2); xticklabels({'Required','Naive m*a'});
grid on; ylabel('Tire force (kN)');
title('Broken: m*a omits road loads');
fprintf('Broken force view at %.1f m/s: naive m*a omits %.1f N of road load.\n', ...
    broken.speedMps,forceBalanceGapN);

%% Broken case changed view - observe the acceleration shortfall
p02Figure('P02BrokenAcceleration','P02 broken acceleration symptom');
bar([broken.accelRequestMps2,naiveRealizedAccelMps2]);
xticks(1:2); xticklabels({'Target','Using naive force'});
grid on; ylabel('Acceleration (m/s^2)');
title('Recognizable symptom: acceleration shortfall');
fprintf('Broken acceleration view: naive result %.3f instead of %.3f m/s^2.\n', ...
    naiveRealizedAccelMps2,broken.accelRequestMps2);

%% Check before teach-back
assert(abs(baseline.forceBalanceResidual) < 1e-9,'Baseline force balance must close.');
assert(any(accelLimited),'Acceleration sweep must cross the grip limit.');
assert(all(~massLimited),'Mass sweep should isolate scaling below the limit.');
assert(all(abs(massDragN-massDragN(1)) < 1e-12), ...
    'Mass sweep must keep fixed-speed aerodynamic drag unchanged.');
assert(naiveTireForceN < broken.tractionLimit, ...
    'Broken case must isolate omitted road loads, not grip saturation.');
disp('Next: run run_checks, then explain mechanism first and consequence second.');

function fig = p02Figure(identifierValue,nameValue)
% Keep exactly one P02 presentation view while preserving unrelated figures.
interactiveExisting = findall(groot,'Type','figure','Tag','P02Interactive');
delete(interactiveExisting);
existing = findall(groot,'Type','figure','Tag','P02Experiment');
delete(existing);
fig = figure('Name',nameValue,'Tag','P02Experiment','UserData',identifierValue, ...
    'NumberTitle','off');
end
