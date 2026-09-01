function interactive
%INTERACTIVE Bounded controls for the P02 longitudinal force balance.
clear model;
modelFcn = @model;

guided = findall(groot,'Type','figure','Tag','P02Experiment');
delete(guided);
existing = findall(groot,'Type','figure','Tag','P02Interactive');
delete(existing);
fig = uifigure('Name','P02 Acceleration and Tire Force','Tag','P02Interactive', ...
    'Position',[100 100 1180 760]);
layout = uigridlayout(fig,[4 4]);
layout.RowHeight = {'1x',44,90,125};
layout.ColumnWidth = {'1x','1x','1x','1x'};

axView = uiaxes(layout);
axView.Layout.Row = 1; axView.Layout.Column = [1 4];

viewBar = uigridlayout(layout,[1 3]);
viewBar.Layout.Row = 2; viewBar.Layout.Column = [1 4];
viewBar.ColumnWidth = {90,180,'1x'};
viewLabel = uilabel(viewBar,'Text','View','HorizontalAlignment','right');
viewLabel.Layout.Row = 1; viewLabel.Layout.Column = 1;
viewDropdown = uidropdown(viewBar,'Items',{'Force balance','Demand curve'}, ...
    'Value','Force balance');
viewDropdown.Layout.Row = 1; viewDropdown.Layout.Column = 2;
focusLabel = uilabel(viewBar,'Text','Select one view, then move one lever and explain that view.');
focusLabel.Layout.Row = 1; focusLabel.Layout.Column = 3;

summary = uilabel(layout,'WordWrap','on','FontName','Courier New');
summary.Layout.Row = 3; summary.Layout.Column = [1 4];

controls = uigridlayout(layout,[2 7]);
controls.Layout.Row = 4; controls.Layout.Column = [1 4];
controls.RowHeight = {38,'1x'};
controls.ColumnWidth = {'1x','1x','1x','1x','1x','1x',100};

addControlLabel(controls,'Acceleration (m/s^2)',1);
addControlLabel(controls,'Mass (kg)',2);
addControlLabel(controls,'Speed (m/s)',3);
addControlLabel(controls,'Grip mu (-)',4);
addControlLabel(controls,'Rolling Crr (-)',5);
addControlLabel(controls,'Drag area CdA (m^2)',6);

accelSlider = uislider(controls,'Limits',[0 10],'Value',3,'MajorTicks',[0 2 4 6 8 10]);
massSlider = uislider(controls,'Limits',[800 2500],'Value',1500, ...
    'MajorTicks',[800 1200 1600 2000 2500]);
speedSlider = uislider(controls,'Limits',[0 70],'Value',20,'MajorTicks',[0 20 40 60 70]);
muSlider = uislider(controls,'Limits',[0.1 1.5],'Value',0.8, ...
    'MajorTicks',[0.1 0.4 0.8 1.2 1.5]);
rollingSlider = uislider(controls,'Limits',[0 0.04],'Value',0.015, ...
    'MajorTicks',[0 0.01 0.02 0.03 0.04]);
dragSlider = uislider(controls,'Limits',[0.3 1.2],'Value',0.65, ...
    'MajorTicks',[0.3 0.6 0.9 1.2]);
sliders = [accelSlider massSlider speedSlider muSlider rollingSlider dragSlider];
for k = 1:numel(sliders)
    sliders(k).Layout.Row = 2;
    sliders(k).Layout.Column = k;
    sliders(k).ValueChangedFcn = @(~,~) renderCurrent();
end

resetButton = uibutton(controls,'Text','Reset baseline','ButtonPushedFcn',@resetInputs);
resetButton.Layout.Row = [1 2]; resetButton.Layout.Column = 7;
viewDropdown.ValueChangedFcn = @(~,~) renderCurrent();

renderCurrent();

    function renderCurrent
        render(accelSlider.Value,massSlider.Value,speedSlider.Value, ...
            muSlider.Value,rollingSlider.Value,dragSlider.Value);
    end

    function render(accelRequest,mass,speed,grip,rolling,dragArea)
        out = modelFcn(accelRequest,mass,speed,grip,rolling,dragArea);

        legend(axView,'off');
        cla(axView,'reset');
        if strcmp(viewDropdown.Value,'Force balance')
            bar(axView,[out.deliveredTireForce,-out.rollingForce, ...
                -out.aerodynamicDragForce,out.netForce]/1000);
            xticks(axView,1:4);
            xticklabels(axView,{'Tire','Rolling','Aero','Net'});
            yline(axView,0,'k-'); grid(axView,'on');
            ylabel(axView,'Longitudinal force (kN)');
            title(axView,'Force balance at the selected point');
        else
            curveAccelMps2 = linspace(0,10,101);
            curveRequiredN = zeros(size(curveAccelMps2));
            curveDeliveredN = zeros(size(curveAccelMps2));
            for n = 1:numel(curveAccelMps2)
                curve = modelFcn(curveAccelMps2(n),mass,speed,grip,rolling,dragArea);
                curveRequiredN(n) = curve.requiredTireForce;
                curveDeliveredN(n) = curve.deliveredTireForce;
            end
            plot(axView,curveAccelMps2,curveRequiredN/1000,'LineWidth',1.3, ...
                'DisplayName','Required');
            hold(axView,'on');
            plot(axView,curveAccelMps2,curveDeliveredN/1000,'LineWidth',1.3, ...
                'DisplayName','Delivered');
            yline(axView,out.tractionLimit/1000,'--','Grip limit');
            plot(axView,out.accelRequestMps2,out.deliveredTireForce/1000,'ko', ...
                'MarkerFaceColor','k','DisplayName','Selected point');
            hold(axView,'off'); grid(axView,'on');
            xlabel(axView,'Requested acceleration (m/s^2)');
            ylabel(axView,'Tire force (kN)');
            title(axView,'Demand and available traction');
            legend(axView,'Location','best');
        end

        if out.tractionLimited
            limitText = 'yes';
        else
            limitText = 'no';
        end
        summary.Text = sprintf([ ...
            'View: %s (change one lever, then explain only this view)\n' ...
            'Required = m*a + rolling + aero = %.1f + %.1f + %.1f = %.1f N\n' ...
            'Delivered %.1f N | limit %.1f N | grip limited: %s\n' ...
            'Requested %.3f m/s^2 | realized %.3f m/s^2 | shortfall %.3f m/s^2\n' ...
            'Observe one lever: which equation term moved first, and why?'], ...
            viewDropdown.Value,out.inertialForce,out.rollingForce,out.aerodynamicDragForce, ...
            out.requiredTireForce,out.deliveredTireForce,out.tractionLimit,limitText, ...
            out.accelRequestMps2,out.realizedAccelMps2,out.accelerationShortfallMps2);
    end

    function resetInputs(~,~)
        accelSlider.Value = 3;
        massSlider.Value = 1500;
        speedSlider.Value = 20;
        muSlider.Value = 0.8;
        rollingSlider.Value = 0.015;
        dragSlider.Value = 0.65;
        renderCurrent();
    end
end

function addControlLabel(parent,textValue,column)
label = uilabel(parent,'Text',textValue,'HorizontalAlignment','center','WordWrap','on');
label.Layout.Row = 1;
label.Layout.Column = column;
end
