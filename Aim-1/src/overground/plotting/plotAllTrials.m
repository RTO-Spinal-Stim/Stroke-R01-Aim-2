function [] = plotAllTrials(allDataTable, figName, baseSavePath, plotFieldName)

%% PURPOSE: PLOT ALL GAIT CYCLES OF ALL TRIALS PER CONDITION ON TOP OF ONE ANOTHER
% Inputs:
% allDataTable: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.

levelNum = 4;

%% Get the list of unique trial names by removing the cycle name.
uniqueNames = getNamesPrefixes(allDataTable.Name, levelNum);

figAllTrials = figure('Name',figName);
figAllTrials.WindowState = 'maximized';
for trialNum = 1:length(uniqueNames)
    currName = uniqueNames{trialNum};
    legendNames = {};
    clf;
    for i = 1:height(allDataTable)
        if ~contains(allDataTable.Name(i), currName)
            continue;
        end
        figAllTrialsConfig.title = [figName ': ' currName ' All Trials Gait Cycles'];        
        cycleData = allDataTable.(plotFieldName)(i);
        nameParts = strsplit(allDataTable.Name(i), '_');
        legendName = strjoin(nameParts(levelNum+1:end), ' ');
        figAllTrialsConfig.tooltipLabel = legendName;
        figAllTrials = plotOneTrialData(cycleData, figAllTrials, figAllTrialsConfig);
        legendNames = [legendNames; {legendName}];        
    end
    h = legend(legendNames);
    set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
    % Save the plot.
    saveFolderPath = baseSavePath;
    if ~isfolder(saveFolderPath)
        mkdir(saveFolderPath);
    end
    savePath = fullfile(saveFolderPath, currName);
    saveas(figAllTrials, [savePath '.fig']);
    saveas(figAllTrials, [savePath '.png']);
    saveas(figAllTrials, [savePath '.svg']);
end

close(figAllTrials);