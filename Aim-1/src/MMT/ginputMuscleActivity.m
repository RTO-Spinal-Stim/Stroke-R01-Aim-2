function [axesTagsStruct] = ginputMuscleActivity(fig, axesTagsStruct)

%% PURPOSE: MANUALLY ANNOTATE WHEN THE MUSCLES OF INTEREST ARE ACTIVE
% Inputs:
% fig: Figure handle
% axesTagsStruct: Struct of axes tags to store the X selections from ginput.

figure(fig);

%% Apply a box using x values specified from clicking on a previous plot with this function.
patchColor = [0.8, 0.8, 0.8];
if nargin==2
    tags = fieldnames(axesTagsStruct);
    for tagNum = 1:length(tags)
        tag = tags{tagNum};
        ax = findobj(fig, 'Type', 'Axes', 'Tag', tag);
        ylims = ax.YLim + [-100, 100]; % Make sure the rectangle is tall enough to accommodate all Y axis limits
        for boxNum = 1:size(axesTagsStruct.(tag).X,1)
            x = axesTagsStruct.(tag).X(boxNum,:);
            if isempty(x)
                continue;
            end
            p = patch(ax, 'XData', [x(1), x(1), x(2), x(2)], 'YData', [ylims(1), ylims(2), ylims(2), ylims(1)], ...
                'FaceColor', patchColor, 'FaceAlpha', 0.7, 'EdgeAlpha', 0);
            uistack(p, 'bottom');
        end
    end
    return;
end

axesTagsStruct = struct;

try
    i = 0;
    while true
        i = i+1;
        answer = questdlg('Any more bursts of EMG activity in the muscles of interest?', ...
                  'Save Dialog', ...
                  'Yes', 'No', 'Cancel', ...
                  'No');
        if ~strcmp(answer, 'Yes')
            break;
        end
        [x, ~] = ginput(2);
        ax = gca;
        tag = ax.Tag;
        ylims = ax.YLim + [-100, 100]; % Make sure the rectangle is tall enough to accommodate all Y axis limits
        x = sort(x); % Account for clicking right to left
        if size(x,1) > size(x,2)
            x = x'; % Make row vector
        end
        if ~isempty(x)
            p = patch('XData', [x(1), x(1), x(2), x(2)], 'YData', [ylims(1), ylims(2), ylims(2), ylims(1)], ...
          'FaceColor', patchColor, 'FaceAlpha', 0.7,'EdgeAlpha', 0);
            uistack(p, 'bottom');
        end
        if ~isfield(axesTagsStruct, tag)
            axesTagsStruct.(tag).X = [];
        end
        axesTagsStruct.(tag).X = [axesTagsStruct.(tag).X; x];
    end
catch
    disp('Stopped adding EMG activation boxes!')
end