%% P01 - Turn Steering and Speed into a Vehicle Path
close all; clc;
out=model(15,5,2.57,1.0,8);

figure('Name','P01 baseline');
subplot(1,2,1);
plot(out.x,out.y,'LineWidth',1.3); axis equal; grid on;
xlabel('Forward position (m)'); ylabel('Lateral position (m)');
title('Realized path');
subplot(1,2,2);
plot(out.speedSweep,out.aySweep/9.80665,'LineWidth',1.3); hold on;
yline(out.mu,'--','Tire limit \mu g');
grid on; xlabel('Speed (m/s)'); ylabel('Requested lateral acceleration (g)');
title('Speed squares the tire demand');

%% Sweep 1 - speed
speeds=[8 15 25];
figure('Name','P01 speed sweep'); hold on; grid on; axis equal;
for i=1:numel(speeds)
    s=model(speeds(i),5,2.57,1.0,8);
    plot(s.x,s.y,'LineWidth',1.1,'DisplayName', ...
        sprintf('v %.0f m/s, demand %.2f g',speeds(i),s.requestedAy/9.80665));
end
xlabel('x (m)'); ylabel('y (m)'); title('Same steer, different physical feasibility');
legend('Location','best');

%% Sweep 2 - grip
mus=[0.5 1.0 1.5];
fprintf('Grip sweep at 25 m/s:\n');
for i=1:numel(mus)
    s=model(25,5,2.57,mus(i),8);
    fprintf('  mu %.1f -> requested %.2f g, realized %.2f g\n', ...
        mus(i),s.requestedAy/9.80665,s.realizedAy/9.80665);
end

%% Broken case - trust geometry beyond friction
broken=model(32,8,2.57,0.7,5);
requestedYaw=broken.requestedYaw;
t=broken.t;
r=32/max(abs(requestedYaw),eps);
xRequested=r*sin(requestedYaw*t);
yRequested=sign(requestedYaw)*r*(1-cos(requestedYaw*t));
figure('Name','P01 broken case');
plot(xRequested,yRequested,'--','LineWidth',1.2,'DisplayName','Impossible kinematic request');
hold on; plot(broken.x,broken.y,'LineWidth',1.3,'DisplayName','Friction-limited motion');
axis equal; grid on; xlabel('x (m)'); ylabel('y (m)');
title('Broken: geometry alone ignores tire force'); legend('Location','best');

assert(out.realizedAy<=out.frictionLimit+eps,'Realized acceleration exceeds friction limit.');
