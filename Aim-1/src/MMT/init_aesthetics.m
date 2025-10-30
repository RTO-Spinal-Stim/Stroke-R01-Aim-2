function [config] = init_aesthetics(config)

%% PURPOSE: INITIALIZE THE CONFIG AESTHETICS

if ~isfield(config, 'AESTHETICS')
    config.AESTHETICS = struct();
end

if ~isfield(config.AESTHETICS, 'LINE_WIDTH')
    config.AESTHETICS.LINE_WIDTH = 1;
end

if ~isfield(config.AESTHETICS, 'TICK_FONT_SIZE')
    config.AESTHETICS.TICK_FONT_SIZE = 14;
end

if ~isfield(config.AESTHETICS, 'LABEL_FONT_SIZE')
    config.AESTHETICS.LABEL_FONT_SIZE = 16;
end

if ~isfield(config.AESTHETICS, 'HIGHLIGHT_EDGE_COLOR')
    config.AESTHETICS.HIGHLIGHT_EDGE_COLOR = [0.9922, 0.4157, 0];
end

if ~isfield(config.AESTHETICS, 'HIGHLIGHT_FILL_COLOR')
    config.AESTHETICS.HIGHLIGHT_FILL_COLOR = [1, 1, 1];
end

if ~isfield(config.AESTHETICS, 'COMMENT_FONT_SIZE')
    config.AESTHETICS.COMMENT_FONT_SIZE = 12;
end