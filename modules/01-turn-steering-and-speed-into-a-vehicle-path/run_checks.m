function run_checks
a=model(10,5,2.57,1,5);
b=model(20,5,2.57,1,5);
assert(abs(b.requestedAy/a.requestedAy-4)<1e-10,'Lateral demand should scale with speed squared.');
assert(a.realizedAy<=a.frictionLimit+eps,'Friction limit violated.');
straight=model(15,0,2.57,1,5);
assert(straight.requestedAy==0,'Zero steer should request zero lateral acceleration.');
lowGrip=model(30,8,2.57,0.4,5);
assert(lowGrip.realizedAy < lowGrip.requestedAy,'Low-grip case should saturate.');
disp('P01 checks passed.');
end
