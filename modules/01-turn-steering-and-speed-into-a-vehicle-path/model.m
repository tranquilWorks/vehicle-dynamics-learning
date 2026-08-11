function out = model(speed,steerDeg,wheelbase,mu,duration)
%MODEL Kinematic bicycle request with friction-limited realized motion.
arguments
    speed (1,1) double {mustBeNonnegative} = 15
    steerDeg (1,1) double = 5
    wheelbase (1,1) double {mustBePositive} = 2.57
    mu (1,1) double {mustBePositive} = 1.0
    duration (1,1) double {mustBePositive} = 8
end
g=9.80665;
delta=deg2rad(steerDeg);
if abs(delta)<1e-9 || speed==0
    radius=inf; requestedAy=0; requestedYaw=0;
else
    radius=wheelbase/tan(delta);
    requestedYaw=speed/radius;
    requestedAy=speed^2/abs(radius);
end
limitAy=mu*g;
realizedAy=min(requestedAy,limitAy);
realizedYaw=sign(requestedYaw)*realizedAy/max(speed,eps);
t=linspace(0,duration,500);
if abs(realizedYaw)<1e-9
    x=speed*t; y=zeros(size(t));
else
    rReal=speed/realizedYaw;
    x=rReal*sin(realizedYaw*t);
    y=rReal*(1-cos(realizedYaw*t));
end
speeds=linspace(0,max(5,1.5*speed),200);
if isinf(radius)
    aySweep=zeros(size(speeds));
else
    aySweep=speeds.^2/abs(radius);
end
out=struct('t',t,'x',x,'y',y,'radius',radius,'requestedAy',requestedAy, ...
    'realizedAy',realizedAy,'frictionLimit',limitAy,'utilization',requestedAy/limitAy, ...
    'requestedYaw',requestedYaw,'realizedYaw',realizedYaw,'speedSweep',speeds, ...
    'aySweep',aySweep,'wheelbase',wheelbase,'mu',mu);
end
