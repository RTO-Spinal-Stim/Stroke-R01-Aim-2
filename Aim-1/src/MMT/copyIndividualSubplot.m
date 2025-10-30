function [newFig] = copyIndividualSubplot(originalFig, targetTags)
%% PURPOSE: SAVE A SINGLE SUBPLOT WITH IDENTICAL SIZE AND ASPECT RATIO
% Inputs:
% originalFig: Handle to the original N x 2 figure
% targetTags: The muscle names to copy the plots from the original figure
% fileName: The file name to save the figure to.
%
% Outputs:
% newFig: Handle to the newly created figure with just the muscles of interest

newFig = false;

% Ensure targetTags is a cell array
if ischar(targetTags) || isstring(targetTags)
    targetTags = {targetTags};
end

% Find all target axes
targetAxes = [];
for i = 1:length(targetTags)
    ax = findobj(originalFig, 'Type', 'axes', 'Tag', targetTags{i});
    if ~isempty(ax)
        targetAxes = [targetAxes; ax(1)]; % Take first match if multiple
    else
        warning('No axes found with tag: %s', targetTags{i});
    end
end

if isempty(targetAxes)
    warning('No valid axes found for the specified tags');
    return;
end

numPlots = length(targetAxes);

% Maximize the original figure
set(originalFig, 'WindowState', 'maximized');
pause(0.5); % Small pause to ensure maximization is complete

% Get the position of the first target axes in the maximized original figure
originalPos_norm = get(targetAxes(1), 'OuterPosition'); % [left bottom width height] in normalized units
originalFigPos_px = get(originalFig, 'OuterPosition'); % [left bottom width height] in pixels

% Calculate the actual pixel dimensions of one subplot
subplotWidth_outer_px = originalPos_norm(3) * originalFigPos_px(3);
subplotHeight_outer_px = originalPos_norm(4) * originalFigPos_px(4);

% Create new figure and maximize it initially
newFig = figure();
set(newFig, 'WindowState', 'maximized');
pause(0.5); % Small pause to ensure maximization is complete

% Copy each axes to the maximized new figure
copiedAxes = [];
for i = 1:numPlots
    newAx = copyobj(targetAxes(i), newFig);
    copiedAxes = [copiedAxes; newAx];
end

% Put the xlabel below the lowest axes
lowestAx = copiedAxes(end);
lowestAx.PositionConstraint = "innerposition";
prevPos = lowestAx.OuterPosition;
xlabel(lowestAx, 'Time (sec)');
newPos = lowestAx.OuterPosition;
newInnerPos = lowestAx.InnerPosition;
xlabel_height_norm = newPos(4) - prevPos(4);
xlabel_height_px = xlabel_height_norm * newFig.Position(4);
xlabel_and_xticks_height_px = (newPos(4) - newInnerPos(4)) * newFig.Position(4);

% Calculate spacing between plots and margins
verticalSpacing = 20; % pixels between plots
horizontalMargin = 10; % pixels on left and right
bottomMargin = 20; % pixels on bottom
topMargin = 40; % pixels on top

% Calculate total required figure dimensions
totalWidth_px = subplotWidth_outer_px + 2 * horizontalMargin;
totalHeight_px = (numPlots * subplotHeight_outer_px) + ((numPlots - 1) * verticalSpacing) + bottomMargin + topMargin + xlabel_height_px;

newFigPos_px = newFig.Position; % Pixels
newFigPos_px(3:4) = [totalWidth_px, totalHeight_px];
set(newFig, 'Position', newFigPos_px);

% Position the copied axes to be stacked vertically
defaultColors = get(gca,'ColorOrder');
for i = 1:numPlots
    targetAx = targetAxes(i);
    copiedAx = copiedAxes(i);
    set(targetAx, 'Units','pixels');    
    targetAxPos = targetAx.Position;
    set(targetAx, 'Units', 'normalized');
    targetAxHeight = targetAxPos(4);
    targetAxWidth = targetAxPos(3);

    % Calculate position in pixels from bottom (Y) and left (X)
    yPosPixels = bottomMargin + (numPlots - i) * (subplotHeight_outer_px + verticalSpacing) + xlabel_and_xticks_height_px; % 2*xlabel_height_px to account for 
    xPosPixels = (totalWidth_px - targetAxWidth)/2;    

    set(copiedAx, 'Units', 'pixels');
    
    % Set the position of this axes
    set(copiedAx, 'Position', [xPosPixels, yPosPixels, targetAxWidth, targetAxHeight]);   

    % Change the color of the line
    lineHandle = findobj(copiedAx, 'Type' ,'line');
    if ~isempty(lineHandle)        
        set(lineHandle(1), 'Color', defaultColors(1,:));
    end

    % Place the plot relative to the right edge    
    copiedAxPosition = copiedAx.Position;
    copiedAxPosition(1) = totalWidth_px - horizontalMargin - copiedAxPosition(3);
    copiedAx.Position = copiedAxPosition;
end

% Set the new figure's title
tagsStr = '';
for i = 1:length(targetTags)
    tagsStr = [tagsStr ', ' targetTags{i}];
end
tagsStr = tagsStr(3:end); % Omit the leading ', '
newFig.Name = tagsStr;