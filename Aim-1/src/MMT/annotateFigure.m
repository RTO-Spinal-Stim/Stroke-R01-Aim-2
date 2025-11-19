function [] = annotateFigure(fig, com, comtext, muscleNames)

%% PURPOSE: ANNOTATE THE EMG TIMESERIES WITH COMMENTS
% Inputs:
% fig: The handle of the figure to annotate
% com: The comments locations
% comtext: The text of the comments
% muscleNames: The muscles of interest during this file's motion.

if ~iscell(muscleNames)
    muscleNames = {muscleNames};
end

% Put all of the comments in as vertical lines
figure(fig);
axHandles = findall(fig, 'Type', 'axes');
commentsIdx = com(:,3);
commentsNum = com(:,5); % The index of the comment value
comments = comtext;
for axNum = 1:length(axHandles)
    ax = axHandles(axNum);
    hold(ax, 'on');

    % Check if this axes tag matches any muscle name from muscleNames. 
    % If so, change the line color.
    axTag = get(ax, 'Tag');
    if ismember(axTag, muscleNames)
        % Find the line object in this axes
        lineHandle = findobj(ax, 'Type' ,'line');
        if ~isempty(lineHandle)
            % Change the color of the line
            set(lineHandle(1), 'Color', 'red');
        end
    end

    % Add vertical lines where the comments are.
    for commentCount = 1:length(commentsIdx)
        commentIdx = commentsIdx(commentCount);
        comment = comments(commentsNum(commentCount),:);
        xline(ax, commentIdx);
        ylims = ax.YLim;
        yVal = ylims(2) - diff(ylims)*0.1;
        xlims = ax.XLim;
        xVal = commentIdx - diff(xlims) * 0.02;
        text(ax, xVal, yVal, comment);
    end
end