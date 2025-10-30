function [] = plotTrialWithGaitEvents(allDataTable, figName, baseSavePath, plotFieldName, framesFieldName)

%% PURPOSE: PLOT THE ENTIRETY OF EACH TRIAL ALONG WITH THE GAIT EVENTS.
% Inputs:
% allDataStruct: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.
% framesFieldName: The field used for frame numbers.

figOneTrial = figure('Name',figName);
figOneTrial.WindowState = 'maximized';
figOneTrialConfig.color = 'k';
for i = 1:height(allDataTable)
    clf;
    name = char(allDataTable.Name(i));
    displayName = strrep(name, '_', ' ');
    trialData = allDataTable.(plotFieldName)(i);
    figOneTrialConfig.title = [figName ': ' displayName];
    figOneTrial = plotOneTrialData(trialData, figOneTrial, figOneTrialConfig);
    %% Plot the gait phases & events
    axHandles = findobj(figOneTrial, 'Type', 'axes');
    framesStruct = allDataTable.(framesFieldName)(i);
    for axNum = 1:length(axHandles)
        ax = axHandles(axNum);
        plotGaitEvents(framesStruct, ax);
    end
    % Save the plot.
    saveFolderPath = baseSavePath;
    if ~isfolder(saveFolderPath)
        mkdir(saveFolderPath);
    end
    savePath = fullfile(saveFolderPath, name);
    saveas(figOneTrial, [savePath '.fig']);
    saveas(figOneTrial, [savePath '.png']);
    saveas(figOneTrial, [savePath '.svg']);
end
close(figOneTrial);