function [] = reorderFigure(fig, musclesOrdered)

%% PURPOSE: REORDER THE SUBPLOTS FOR EACH MUSCLE'S EMG DATA IN A FIGURE
% Inputs:
% fig: The figure with the subplots to reorder
% musclesOrdered: The order to put the plots in. Exclude L/R from start of
% muscle abbreviation. e.g. 'TA' rather than 'LTA'

allAxes = findobj(fig, 'Type', 'Axes');
allPos = struct;
for i = 1:length(allAxes)
    tag = allAxes(i).Tag;
    allPos.(tag) = allAxes(i).Position;
end

% Pull out the heights (position #2) into an array
allPosNames = fieldnames(allPos);
allHeights = NaN(length(allPosNames),1);
for i = 1:length(allHeights)
    tag = allPosNames{i};
    allHeights(i) = allPos.(tag)(2);
end

allHeights = sort(unique(allHeights), 'descend');

assert(length(allHeights) == length(musclesOrdered), 'Mismatch in number of axes and number of muscles specified')

% Get the xlabel
for axNum = 1:length(allAxes)
    ax = allAxes(axNum);
    if ~isempty(ax.XLabel.String)
        xlabelObj = ax.XLabel;        
        break;
    end
end

% Go through the axes, get their tag, and find the index of that tag in the
% musclesOrdered. Set the axes height to the height at that index
for axNum = 1:length(allAxes)
    ax = allAxes(axNum);
    tag = ax.Tag(2:end);
    tagIdx = ismember(musclesOrdered, tag);
    ax.Position(2) = allHeights(tagIdx);  
    if tagIdx(end)
        ax.XLabel = copyobj(xlabelObj, ax);
    end
end

for axNum = 1:length(allAxes)
    ax = allAxes(axNum);
    tag = ax.Tag(2:end);
    tagIdx = ismember(musclesOrdered, tag);
    if ~tagIdx(end)
        delete(ax.XLabel);
    end
end

