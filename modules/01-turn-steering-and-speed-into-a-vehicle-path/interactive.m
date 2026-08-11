function interactive
fig=uifigure('Name','P01 Vehicle Path and Grip','Position',[100 100 1120 720]);
g=uigridlayout(fig,[3 5]); g.RowHeight={'1x','1x',100};
axPath=uiaxes(g); axPath.Layout.Row=1; axPath.Layout.Column=[1 3];
axDemand=uiaxes(g); axDemand.Layout.Row=1; axDemand.Layout.Column=[4 5];
axYaw=uiaxes(g); axYaw.Layout.Row=2; axYaw.Layout.Column=[1 4];
summary=uilabel(g,'WordWrap','on'); summary.Layout.Row=2; summary.Layout.Column=5;

vS=uislider(g,'Limits',[0 45],'Value',15,'MajorTicks',[0 10 20 30 40 45]);
vS.Layout.Row=3; vS.Layout.Column=1;
dS=uislider(g,'Limits',[-15 15],'Value',5,'MajorTicks',[-15 -10 -5 0 5 10 15]);
dS.Layout.Row=3; dS.Layout.Column=2;
muS=uislider(g,'Limits',[0.2 2],'Value',1,'MajorTicks',[0.2 0.5 1 1.5 2]);
muS.Layout.Row=3; muS.Layout.Column=3;
lS=uislider(g,'Limits',[1.5 4],'Value',2.57); lS.Layout.Row=3; lS.Layout.Column=4;
tS=uislider(g,'Limits',[2 15],'Value',8); tS.Layout.Row=3; tS.Layout.Column=5;
controls=[vS dS muS lS tS];
for i=1:numel(controls)
    controls(i).ValueChangingFcn=@(~,~) updatePlots();
    controls(i).ValueChangedFcn=@(~,~) updatePlots();
end
updatePlots();

    function updatePlots
        out=model(vS.Value,dS.Value,lS.Value,muS.Value,tS.Value);
        cla(axPath); plot(axPath,out.x,out.y,'LineWidth',1.3);
        axis(axPath,'equal'); grid(axPath,'on'); xlabel(axPath,'x (m)'); ylabel(axPath,'y (m)');
        title(axPath,'Friction-limited path');

        cla(axDemand); plot(axDemand,out.speedSweep,out.aySweep/9.80665,'LineWidth',1.2);
        hold(axDemand,'on'); yline(axDemand,out.mu,'--'); hold(axDemand,'off');
        grid(axDemand,'on'); xlabel(axDemand,'Speed (m/s)'); ylabel(axDemand,'Demand (g)');
        title(axDemand,'Lateral demand');

        cla(axYaw); bar(axYaw,[out.requestedYaw out.realizedYaw]);
        xticks(axYaw,[1 2]); xticklabels(axYaw,{'Requested','Realized'});
        ylabel(axYaw,'Yaw rate (rad/s)'); grid(axYaw,'on'); title(axYaw,'What the tires can actually deliver');

        summary.Text=sprintf(['speed %.1f m/s\nsteer %.1f deg\nmu %.2f\n' ...
            'requested %.2f g\nrealized %.2f g\nutilization %.0f%%'], ...
            vS.Value,dS.Value,muS.Value,out.requestedAy/9.80665, ...
            out.realizedAy/9.80665,100*out.utilization);
    end
end
