function [] = plotGaitEvents(framesStruct, ax)

%% PURPOSE: PLOT THE GAIT EVENTS LISTED IN THE framesStruct.

if ~exist('ax','var')
    ax = gca;
end

gaitEvents = framesStruct.gaitEvents;
gaitPhases = framesStruct.gaitPhases;

%% Gait Events
% LHS
for i = 1:length(gaitEvents.leftHeelStrikes)
    LHS = gaitEvents.leftHeelStrikes(i);
    xline(ax, LHS, 'b');
end

% RHS
for i = 1:length(gaitEvents.rightHeelStrikes)
    RHS = gaitEvents.rightHeelStrikes(i);
    xline(ax, RHS, 'm');
end

% LTO
for i = 1:length(gaitEvents.leftToeOffs)
    LTO = gaitEvents.leftToeOffs(i);
    xline(ax, LTO, 'b','LineStyle', '--');
end

% RTO
for i = 1:length(gaitEvents.rightToeOffs)
    RTO = gaitEvents.rightToeOffs(i);
    xline(ax, RTO, 'm', 'LineStyle', '--');
end

%% Gait Phases
ylims = ax.YLim;
% L stance phase
p = gobjects(size(gaitPhases.leftStanceStartStop,1),1);
for i = 1:size(gaitPhases.leftStanceStartStop,1)
    startFrame = gaitPhases.leftStanceStartStop(i,1);
    endFrame = gaitPhases.leftStanceStartStop(i,2);
    p(i) = patch(ax, [startFrame, startFrame, endFrame, endFrame], [ylims(1), ylims(2), ylims(2), ylims(1)], 'b', 'FaceAlpha', 0.2);    
end
uistack(p,'bottom');

% R stance phase
p = gobjects(size(gaitPhases.rightStanceStartStop,1),1);
for i = 1:size(gaitPhases.rightStanceStartStop,1)
    startFrame = gaitPhases.rightStanceStartStop(i,1);
    endFrame = gaitPhases.rightStanceStartStop(i,2);
    p(i) = patch(ax, [startFrame, startFrame, endFrame, endFrame], [ylims(1), ylims(2), ylims(2), ylims(1)], 'm', 'FaceAlpha', 0.2);    
end
uistack(p,'bottom');

% % L swing phase
% p = gobjects(size(gaitPhases.leftSwingStartStop,1),1);
% for i = 1:size(gaitPhases.leftSwingStartStop,1)
%     startFrame = gaitPhases.leftSwingStartStop(i,1);
%     endFrame = gaitPhases.leftSwingStartStop(i,2);
%     p(i) = patch(ax, [startFrame, startFrame, endFrame, endFrame], [ylims(1), ylims(2), ylims(2), ylims(1)], 'b', 'FaceAlpha', 0.2);
% end
% uistack(p, 'bottom');
% 
% % R swing phase
% p = gobjects(size(gaitPhases.rightSwingStartStop,1),1);
% for i = 1:size(gaitPhases.rightSwingStartStop,1)
%     startFrame = gaitPhases.rightSwingStartStop(i,1);
%     endFrame = gaitPhases.rightSwingStartStop(i,2);
%     p(i) = patch(ax, [startFrame, startFrame, endFrame, endFrame], [ylims(1), ylims(2), ylims(2), ylims(1)], 'm', 'FaceAlpha', 0.2);
% end
% uistack(p, 'bottom');