function run_checks
%RUN_CHECKS Independent deterministic checks for the P02 force balance.
clear model;
modelFcn = @model;
g = 9.80665;
rho = 1.225;

baseline = modelFcn(3,1500,20,0.8,0.015,0.65);
repeat = modelFcn(3,1500,20,0.8,0.015,0.65);
defaultBaseline = modelFcn();
assert(isequaln(baseline,repeat),'Identical inputs must produce identical outputs.');
assert(isequaln(baseline,defaultBaseline),'Documented defaults must reproduce the baseline.');

expectedInertiaN = 1500*3;
expectedRollingN = 0.015*1500*g;
expectedDragN = 0.5*rho*0.65*20^2;
expectedRequiredN = expectedInertiaN+expectedRollingN+expectedDragN;
expectedLimitN = 0.8*1500*g;
assert(abs(baseline.inertialForce-expectedInertiaN) < 1e-9,'Independent m*a check failed.');
assert(abs(baseline.rollingForce-expectedRollingN) < 1e-9,'Independent rolling-force check failed.');
assert(abs(baseline.aerodynamicDragForce-expectedDragN) < 1e-9,'Independent drag check failed.');
assert(abs(baseline.requiredTireForce-expectedRequiredN) < 1e-9,'Required-force sum is wrong.');
assert(abs(baseline.tractionLimit-expectedLimitN) < 1e-9,'Independent grip-limit check failed.');
assert(abs(baseline.realizedAccelMps2-3) < 1e-12,'Feasible request should be realized exactly.');
assert(abs(baseline.forceBalanceResidual) < 1e-9,'Baseline force balance does not close.');
assert(baseline.deliveredTireForce <= baseline.tractionLimit,'Delivered force exceeds grip.');

lowAccel = modelFcn(2,1500,20,0.8,0.015,0.65);
highAccel = modelFcn(4,1500,20,0.8,0.015,0.65);
assert(abs((highAccel.requiredTireForce-lowAccel.requiredTireForce)-1500*2) < 1e-9, ...
    'Acceleration-sweep force slope should equal mass.');

accelSweepMps2 = [0 2 4 6 8];
accelLimited = false(size(accelSweepMps2));
for k = 1:numel(accelSweepMps2)
    swept = modelFcn(accelSweepMps2(k),1500,20,0.8,0.015,0.65);
    accelLimited(k) = swept.tractionLimited;
end
assert(any(~accelLimited) && any(accelLimited), ...
    'Acceleration sweep must contain feasible and grip-limited requests.');

light = modelFcn(3,900,20,0.8,0.015,0.65);
heavy = modelFcn(3,2100,20,0.8,0.015,0.65);
expectedMassDeltaN = (2100-900)*(3+0.015*g);
assert(abs((heavy.requiredTireForce-light.requiredTireForce)-expectedMassDeltaN) < 1e-9, ...
    'Mass sweep must scale inertia and rolling force while drag stays fixed.');
assert(abs(heavy.aerodynamicDragForce-light.aerodynamicDragForce) < 1e-12, ...
    'Mass sweep must hold aerodynamic drag fixed.');

massSweepKg = [900 1200 1500 1800 2100];
massLimited = false(size(massSweepKg));
for k = 1:numel(massSweepKg)
    swept = modelFcn(3,massSweepKg(k),20,0.8,0.015,0.65);
    massLimited(k) = swept.tractionLimited;
end
assert(all(~massLimited),'Mass sweep must stay feasible so it isolates mass scaling.');

zeroRequest = modelFcn(0,1500,20,0.8,0.015,0.65);
assert(abs(zeroRequest.requiredTireForce-zeroRequest.roadLoadForce) < 1e-9, ...
    'Zero acceleration request should require only the road-load force.');
assert(abs(zeroRequest.realizedAccelMps2) < 1e-12, ...
    'Supplying the road-load force should hold speed.');

stationary = modelFcn(0,1500,0,0.8,0.015,0.65);
assert(stationary.rollingForce == 0,'Stationary limiting case should have zero rolling force.');
assert(stationary.aerodynamicDragForce == 0,'Zero speed should produce zero aero drag.');
assert(stationary.requiredTireForce == 0,'Stationary zero request should need zero tire force.');

lowGrip = modelFcn(8,1500,20,0.2,0.015,0.65);
assert(lowGrip.tractionLimited,'Low-grip high-request case must saturate.');
assert(abs(lowGrip.deliveredTireForce-lowGrip.tractionLimit) < 1e-9, ...
    'Saturated delivered force must equal the grip limit.');
expectedLowGripAccel = (lowGrip.tractionLimit-lowGrip.roadLoadForce)/lowGrip.massKg;
assert(abs(lowGrip.realizedAccelMps2-expectedLowGripAccel) < 1e-12, ...
    'Saturated acceleration must follow the independent force balance.');
assert(lowGrip.realizedAccelMps2 < lowGrip.accelRequestMps2, ...
    'Grip saturation must create an acceleration shortfall.');

noGrip = modelFcn(3,1500,20,0,0.015,0.65);
assert(noGrip.deliveredTireForce == 0,'Zero grip should deliver zero tire force.');
assert(noGrip.realizedAccelMps2 < 0,'A moving no-grip car should decelerate under road loads.');
assert(isinf(noGrip.utilization),'A nonzero request at zero grip has infinite utilization.');

zeroEverything = modelFcn(0,1500,0,0,0,0);
assert(zeroEverything.requiredTireForce == 0,'Zero demand and zero loads require zero tire force.');
assert(zeroEverything.utilization == 0,'Zero demand at zero grip has zero utilization by convention.');

broken = modelFcn(3,1500,40,0.8,0.015,0.65);
naiveTireForceN = broken.massKg*broken.accelRequestMps2;
omittedForceN = broken.requiredTireForce-naiveTireForceN;
naiveAccelMps2 = (naiveTireForceN-broken.roadLoadForce)/broken.massKg;
assert(abs(omittedForceN-broken.roadLoadForce) < 1e-9, ...
    'Broken-case force error should equal omitted road loads.');
assert(naiveAccelMps2 < broken.accelRequestMps2, ...
    'Ignoring road loads must create the recognizable acceleration shortfall.');
assert(naiveTireForceN < broken.tractionLimit, ...
    'Broken case must isolate omitted road loads rather than grip saturation.');

bounded = modelFcn(20,1e5,120,3,0.1,5);
boundedMetrics = [bounded.normalForce bounded.requiredTireForce bounded.tractionLimit ...
    bounded.deliveredTireForce bounded.realizedAccelMps2 bounded.utilization];
assert(all(isfinite(boundedMetrics)),'Accepted upper bounds must produce finite outputs.');
lowerMassBound = modelFcn(0,1,0,0,0,0);
assert(lowerMassBound.massKg == 1 && isfinite(lowerMassBound.realizedAccelMps2), ...
    'Accepted lower mass bound must remain finite.');

integerBaseline = modelFcn(single(3),int32(1500),uint8(20),single(0.8), ...
    single(0.015),single(0.65));
assert(isa(integerBaseline.massKg,'double') && isa(integerBaseline.speedMps,'double'), ...
    'Accepted real numeric scalar types must normalize to double outputs.');

invalidCases = { ...
    @() modelFcn(-1,1500,20,0.8,0.015,0.65), 'P02:model:AccelerationOutOfRange'; ...
    @() modelFcn(20.1,1500,20,0.8,0.015,0.65), 'P02:model:AccelerationOutOfRange'; ...
    @() modelFcn(3,0,20,0.8,0.015,0.65), 'P02:model:MassOutOfRange'; ...
    @() modelFcn(3,0.999,20,0.8,0.015,0.65), 'P02:model:MassOutOfRange'; ...
    @() modelFcn(3,-1500,20,0.8,0.015,0.65), 'P02:model:MassOutOfRange'; ...
    @() modelFcn(3,100001,20,0.8,0.015,0.65), 'P02:model:MassOutOfRange'; ...
    @() modelFcn(3,1500,-1,0.8,0.015,0.65), 'P02:model:SpeedOutOfRange'; ...
    @() modelFcn(3,1500,120.1,0.8,0.015,0.65), 'P02:model:SpeedOutOfRange'; ...
    @() modelFcn(3,1500,20,-0.1,0.015,0.65), 'P02:model:GripOutOfRange'; ...
    @() modelFcn(3,1500,20,3.1,0.015,0.65), 'P02:model:GripOutOfRange'; ...
    @() modelFcn(3,1500,20,0.8,-0.01,0.65), 'P02:model:RollingOutOfRange'; ...
    @() modelFcn(3,1500,20,0.8,0.11,0.65), 'P02:model:RollingOutOfRange'; ...
    @() modelFcn(3,1500,20,0.8,0.015,-0.65), 'P02:model:DragAreaOutOfRange'; ...
    @() modelFcn(3,1500,20,0.8,0.015,5.1), 'P02:model:DragAreaOutOfRange'; ...
    @() modelFcn(NaN,1500,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn(3,Inf,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn([2 3],1500,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn(3,1500+1i,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn(3,'1500',20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn([],1500,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn(true,1500,20,0.8,0.015,0.65), 'P02:model:InvalidInput'; ...
    @() modelFcn(struct(),1500,20,0.8,0.015,0.65), 'P02:model:InvalidInput'};
for k = 1:size(invalidCases,1)
    assertRejects(invalidCases{k,1},invalidCases{k,2},sprintf('invalid input case %d',k));
    recovered = modelFcn(3,1500,20,0.8,0.015,0.65);
    assert(isequaln(baseline,recovered),sprintf( ...
        'Valid call after rejected input case %d did not reproduce the baseline.',k));
end

afterErrors = modelFcn(3,1500,20,0.8,0.015,0.65);
assert(isequaln(baseline,afterErrors), ...
    'A valid call after rejected inputs must recover without state contamination.');
mutatedCopy = baseline;
mutatedCopy.requiredTireForce = -1;
afterMutation = modelFcn(3,1500,20,0.8,0.015,0.65);
assert(afterMutation.requiredTireForce == baseline.requiredTireForce, ...
    'Changing a returned struct must not contaminate later model calls.');
disp('P02 checks passed.');
end

function assertRejects(operation,expectedId,label)
caughtId = '';
try
    operation();
catch err
    caughtId = err.identifier;
end
assert(strcmp(caughtId,expectedId),sprintf('%s: expected %s, received %s.', ...
    label,expectedId,caughtId));
end
