function [] = plotRawAndFilteredData(allDataTable, figName, baseSavePath, plotColumnNames, rectify)

%% PURPOSE: PLOT THE RAW AND FILTERED DATA ON TOP OF ONE ANOTHER.
% Inputs:
% allDataTable: Table where each row is one trial
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotColumnNames: Struct listing the raw & filtered column names.

if ~exist('rectify','var')
    rectify = false;
end

if ~isstruct(plotColumnNames) || ~isfield(plotColumnNames, 'Raw') || ~isfield(plotColumnNames, 'Filtered')
    error('plotColumnNames arg must be a struct with fields "Raw" and "Filtered", whose values are column names in the data table.');
end

figOneTrial = figure('Name',figName);
figOneTrial.WindowState = 'maximized';
figOneTrialConfig.color = '';
raw_label = 'Raw';
if rectify
    raw_label = 'Rectified Raw';
end
for i = 1:height(allDataTable)
    name = char(allDataTable.Name(i));
    clf;
    trialDataRaw = allDataTable.(plotColumnNames.Raw)(i);
    if rectify
        trialDataFields = fieldnames(trialDataRaw);
        for fieldNum = 1:length(trialDataFields)
            fieldName = trialDataFields{fieldNum};
            trialDataRaw.(fieldName) = abs(trialDataRaw.(fieldName));
        end
    end
    trialDataFiltered = allDataTable.(plotColumnNames.Filtered)(i);
    figOneTrialConfig.title = [figName ': ' name];
    figOneTrialConfig = rmfield(figOneTrialConfig, 'color');
    figOneTrial = plotOneTrialData(trialDataRaw, figOneTrial, figOneTrialConfig);
    figOneTrialConfig.color = 'r';
    figOneTrial = plotOneTrialData(trialDataFiltered, figOneTrial, figOneTrialConfig);
    h = legend({raw_label,'Filtered'});
    set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
    % Save the plot.
    saveFolderPath = baseSavePath;
    mkdir(saveFolderPath);
    savePath = fullfile(saveFolderPath, name);
    saveas(figOneTrial, [savePath '.fig']);
    saveas(figOneTrial, [savePath '.png']);
    saveas(figOneTrial, [savePath '.svg']);
end
close(figOneTrial);



% for i = 1:length(intervention_field_names)
%     intervention_field_name = intervention_field_names{i};
%     speedNames = fieldnames(allDataTable.(intervention_field_name));
%     for speedNum = 1:length(speedNames)
%         speedName = speedNames{speedNum};
%         prePosts = fieldnames(allDataTable.(intervention_field_name).(speedName));
%         for prePostNum = 1:length(prePosts)
%             prePost = prePosts{prePostNum};
%             trialNames = fieldnames(allDataTable.(intervention_field_name).(speedName).(prePost).Trials);     
%             for trialNum = 1:length(trialNames)
%                 trialName = trialNames{trialNum};
%                 clf;
%                 trialDataRaw = allDataTable.(intervention_field_name).(speedName).(prePost).Trials.(trialName).Loaded;
%                 % Rectify the EMG data if specified.
%                 raw_label = 'Raw';
%                 if rectify
%                     raw_label = 'Rectified Raw';
%                     trialDataFields = fieldnames(trialDataRaw);
%                     for fieldNum = 1:length(trialDataFields)
%                         fieldName = trialDataFields{fieldNum};
%                         trialDataRaw.(fieldName) = abs(trialDataRaw.(fieldName));
%                     end
%                 end
%                 trialDataFiltered = allDataTable.(intervention_field_name).(speedName).(prePost).Trials.(trialName).Filtered;
%                 figOneTrialConfig.title = [figName ': ' intervention_field_name ' ' speedName ' ' prePost ' ' trialName];
%                 figOneTrialConfig = rmfield(figOneTrialConfig, 'color');
%                 figOneTrial = plotOneTrialData(trialDataRaw, figOneTrial, figOneTrialConfig);
%                 figOneTrialConfig.color = 'r';
%                 figOneTrial = plotOneTrialData(trialDataFiltered, figOneTrial, figOneTrialConfig);
%                 h = legend({raw_label,'Filtered'});
%                 set(h, 'Position', [0.4825, 0.4903, 0.0562, 0.1391]); % In the middle of the axes.
%                 % Save the plot.
%                 saveFolderPath = baseSavePath;
%                 mkdir(saveFolderPath);
%                 savePath = fullfile(saveFolderPath, [intervention_field_name '_' prePost '_' speedName '_' trialName]);
%                 saveas(figOneTrial, [savePath '.fig']);
%                 saveas(figOneTrial, [savePath '.png']);
%                 saveas(figOneTrial, [savePath '.svg']);
%             end
%         end
%     end
% end
% close(figOneTrial);