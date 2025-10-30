function [] = setAesthetics(fig, aesthetics_config)

%% PURPOSE: SET THE AESTHETICS OF THE SUPPLIED FIGURE
% Inputs:
% fig: The figure to modify
% aesthetics_config: Config struct containing the aesthetics

allAx = findobj(fig, 'Type', 'Axes');
for axNum = 1:length(allAx)
    ax = allAx(axNum);
    ax.FontSize = aesthetics_config.TICK_FONT_SIZE;

    % Line
    lineHandle = findobj(ax, 'Type', 'Line');
    lineHandle.LineWidth = aesthetics_config.LINE_WIDTH;

    % Comments
    commentHandles = findobj(ax, 'Type', 'Text');
    for commentNum = 1:length(commentHandles)
        commentHandle = commentHandles(commentNum);
        commentHandle.FontSize = aesthetics_config.COMMENT_FONT_SIZE;
    end

    patchHandles = findobj(ax, 'Type', 'Patch');
    for patchNum = 1:length(patchHandles)
        patchHandle = patchHandles(patchNum);
        patchHandle.FaceColor = aesthetics_config.HIGHLIGHT_COLOR;
        patchHandle.LineWidth = 3;
    end

end