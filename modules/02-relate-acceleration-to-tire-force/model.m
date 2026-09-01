function out = model(accelRequestMps2,massKg,speedMps,mu,rollingCoefficient,dragAreaM2)
%MODEL Transparent aggregate longitudinal tire-force balance.
%   Positive force and acceleration point forward. The car travels on a
%   level road, and the aggregate tire force is traction-only. Axle load
%   transfer, combined cornering force, slip, and driveline dynamics are
%   intentionally outside P02.
arguments
    accelRequestMps2 = 3
    massKg = 1500
    speedMps = 20
    mu = 0.8
    rollingCoefficient = 0.015
    dragAreaM2 = 0.65
end

validateRealFiniteScalar(accelRequestMps2,'accelRequestMps2');
validateRealFiniteScalar(massKg,'massKg');
validateRealFiniteScalar(speedMps,'speedMps');
validateRealFiniteScalar(mu,'mu');
validateRealFiniteScalar(rollingCoefficient,'rollingCoefficient');
validateRealFiniteScalar(dragAreaM2,'dragAreaM2');

% Normalize accepted integer and single inputs so every calculation and
% returned metric uses the same base-MATLAB double-precision arithmetic.
accelRequestMps2 = double(accelRequestMps2);
massKg = double(massKg);
speedMps = double(speedMps);
mu = double(mu);
rollingCoefficient = double(rollingCoefficient);
dragAreaM2 = double(dragAreaM2);

if accelRequestMps2 < 0 || accelRequestMps2 > 20
    error('P02:model:AccelerationOutOfRange', ...
        'accelRequestMps2 must be between 0 and 20 m/s^2.');
end
if massKg < 1 || massKg > 1e5
    error('P02:model:MassOutOfRange','massKg must be between 1 and 100000 kg.');
end
if speedMps < 0 || speedMps > 120
    error('P02:model:SpeedOutOfRange','speedMps must be between 0 and 120 m/s.');
end
if mu < 0 || mu > 3
    error('P02:model:GripOutOfRange','mu must be between 0 and 3.');
end
if rollingCoefficient < 0 || rollingCoefficient > 0.1
    error('P02:model:RollingOutOfRange', ...
        'rollingCoefficient must be between 0 and 0.1.');
end
if dragAreaM2 < 0 || dragAreaM2 > 5
    error('P02:model:DragAreaOutOfRange','dragAreaM2 must be between 0 and 5 m^2.');
end

g = 9.80665;                 % gravitational acceleration (m/s^2)
airDensity = 1.225;          % reference air density (kg/m^3)
normalForce = massKg*g;      % aggregate level-road normal force (N)
inertialForce = massKg*accelRequestMps2;
if speedMps == 0
    rollingForce = 0;        % no rolling loss while stationary in this model
else
    rollingForce = rollingCoefficient*normalForce;
end
aerodynamicDragForce = 0.5*airDensity*dragAreaM2*speedMps^2;
roadLoadForce = rollingForce+aerodynamicDragForce;
requiredTireForce = inertialForce+roadLoadForce;
tractionLimit = mu*normalForce;
deliveredTireForce = min(requiredTireForce,tractionLimit);
netForce = deliveredTireForce-roadLoadForce;
realizedAccelMps2 = netForce/massKg;

if tractionLimit == 0
    if requiredTireForce == 0
        utilization = 0;
    else
        utilization = inf;
    end
else
    utilization = requiredTireForce/tractionLimit;
end

out = struct( ...
    'accelRequestMps2',accelRequestMps2, ...
    'massKg',massKg, ...
    'speedMps',speedMps, ...
    'mu',mu, ...
    'rollingCoefficient',rollingCoefficient, ...
    'dragAreaM2',dragAreaM2, ...
    'g',g, ...
    'airDensity',airDensity, ...
    'normalForce',normalForce, ...
    'inertialForce',inertialForce, ...
    'rollingForce',rollingForce, ...
    'aerodynamicDragForce',aerodynamicDragForce, ...
    'roadLoadForce',roadLoadForce, ...
    'requiredTireForce',requiredTireForce, ...
    'tractionLimit',tractionLimit, ...
    'deliveredTireForce',deliveredTireForce, ...
    'netForce',netForce, ...
    'realizedAccelMps2',realizedAccelMps2, ...
    'accelerationShortfallMps2',accelRequestMps2-realizedAccelMps2, ...
    'forceMargin',tractionLimit-requiredTireForce, ...
    'utilization',utilization, ...
    'tractionLimited',requiredTireForce > tractionLimit, ...
    'forceBalanceResidual',deliveredTireForce-roadLoadForce-massKg*realizedAccelMps2);
end

function validateRealFiniteScalar(value,name)
if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
    error('P02:model:InvalidInput','%s must be a real, finite numeric scalar.',name);
end
end
