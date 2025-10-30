function [fig] = plotOneTrialData(allData, fig, config)

%% PURPOSE: PLOT ONE TRIAL (OR GAIT CYCLE) OF XSENS OR DELSYS EMG DATA
% Inputs:
% data: struct, where each field is one muscle or one joint
% fig: figure handle. Use `gcf` to create a new figure.
% config: The configuration struct
%   fields: cell array of chars of the fields to be plotted.
%   xVector: 1xN numeric for the X axis, where N is the length of the data.
%   xLim: 1x2 numeric
%   title: char
%   xLabel: char
%   numCols: scalar double
%   tooltipLabel: char
%   color: char, or cell array.

if ~exist('fig','var')
    fig = gcf;
end

%% Provide defaults for config.
if ~exist('config','var')
    config = struct;    
end

fieldsToRemove = {};

if ~isfield(config, 'fields')
    config.fields = {};
    fieldsToRemove = [fieldsToRemove; {'fields'}];
end

if ~isfield(config, 'title')
    config.title = '';
    fieldsToRemove = [fieldsToRemove; {'title'}];
end

if ~isfield(config, 'xLabel')
    config.xLabel = 'Time';
    fieldsToRemove = [fieldsToRemove; {'xLabel'}];
end

fields = fieldnames(allData);

if ~isfield(config, 'numCols')
    config.numCols = 2;
    fieldsToRemove = [fieldsToRemove; {'numCols'}];
end

if ~isfield(config, 'tooltipLabel')
    config.tooltipLabel = '';
    fieldsToRemove = [fieldsToRemove; {'tooltipLabel'}];
end

if ~isfield(config, 'color')
    config.color = '';
    fieldsToRemove = [fieldsToRemove; {'color'}];
end

numRows = ceil(length(fields)/2);
axHandles = findall(fig, 'Type', 'axes'); % Get all axes handles in the current figure.
% Initialize the axes if they don't already exist.
if isempty(axHandles)
    if isempty(config.fields)
        fieldsReversed = cell(size(fields));
        for i = 1:length(fieldsReversed)
            fieldsReversed{i} = fields{i}(length(fields{i}):-1:1);
        end
        fieldsReversed = sort(fieldsReversed);
        config.fields = cell(size(fieldsReversed));
        for i = 1:length(config.fields)
            config.fields{i} = fieldsReversed{i}(length(fieldsReversed{i}):-1:1);
        end
    end
    axHandles = gobjects(length(config.fields), 1);    
    for i = 1:length(config.fields)
        field = config.fields{i};
        axHandles(i) = axes(fig, 'Tag', field);
        subplot(numRows, config.numCols, i, axHandles(i));
        hold(axHandles(i),'on');
    end
end

%% Plot
for i = 1:length(axHandles)
    ax = axHandles(i);
    field = ax.Tag;
    data = allData.(field);
    if ~isfield(config, 'xVector')
        config.xVector = 1:length(allData.(field));
        fieldsToRemove = [fieldsToRemove; {'xVector'}];
    end
    if ~isfield(config, 'xLim')        
        config.xLim = [min([ax.XLim(1), config.xVector]), max([ax.XLim(2), config.xVector])];
        if ax.XLim(1) == 0 && min(config.xVector) == 1
            config.xLim = [1 config.xLim(2)];
        end
        fieldsToRemove = [fieldsToRemove; {'xLim'}];
    end
    ylim(ax, 'auto');
    if isempty(config.color)        
        p = plot(ax, config.xVector, data);
    else
        p = plot(ax, config.xVector, data, 'Color', config.color);
    end
    label = config.tooltipLabel;
    if ~isempty(label) && ~isempty(config.xVector)
        p.DataTipTemplate.DataTipRows(end+1) = [dataTipTextRow('Name', repmat({label}, size(config.xVector)))];
    end
    if ismember({'xVector'}, fieldsToRemove)
        config = rmfield(config, 'xVector');
        fieldsToRemove(ismember(fieldsToRemove, 'xVector')) = [];
    end
    xlim(ax, config.xLim);
    if ismember({'xLim'}, fieldsToRemove)
        config = rmfield(config, 'xLim');
        fieldsToRemove(ismember(fieldsToRemove, 'xLim')) = [];
    end
    ylabel(ax, field);
    if i >= length(axHandles)-config.numCols+1
        xlabel(ax, config.xLabel);
    end
end

%% Set y axis limits in the same row to the same limits.
for i = 1:config.numCols:length(axHandles)
    ylims = [inf -inf];
    stopAxNumber = min([length(axHandles), i+config.numCols-1]);
    for j = i:stopAxNumber
        ax = axHandles(j);
        axYLim = ax.YLim;
        if axYLim(1) < ylims(1)
            ylims(1) = axYLim(1);
        end
        if axYLim(2) > ylims(2)
            ylims(2) = axYLim(2);
        end
    end
    for j = i:stopAxNumber
        ax = axHandles(j);
        ax.YLim = ylims;
    end    
end

%% Figure settings
displayTitle = strrep(config.title, '_', ' ');
sgtitle(displayTitle,'Interpreter','none');

%% Remove fields from config to prep for the next plot.
for i = 1:length(fieldsToRemove)
    config = rmfield(config, fieldsToRemove{i});
end