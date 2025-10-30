function [] = scatterPlotPerGaitCyclePerIntervention(allDataStruct, figName, baseSavePath, plotFieldName)

%% PURPOSE: SCATTER PLOT THE VALUE FOR EACH GAIT CYCLE, STRATIFIED BY INTERVENTION
% Inputs:
% allDataStruct: One participant's timeseries data.
% figName: A short descriptive name for the figures. Goes in the window
% name and the prefix of the plot titles.
% baseSavePath: The folder to save all of the plots to.
% plotFieldName: The field that is being plotted.

figAllTrials = figure('Name',figName);
figAllTrials.WindowState = 'maximized';
intervention_field_names = fieldnames(allDataStruct);
for i = 1:length(intervention_field_names)
    intervention_field_name = intervention_field_names{i};
    speedNames = fieldnames(allDataStruct.(intervention_field_name));
    for speedNum = 1:length(speedNames)
        speedName = speedNames{speedNum};
        prePostsFields = fieldnames(allDataStruct.(intervention_field_name).(speedName));
        clf;
        ax = axes(figAllTrials);
        hold(ax,'on');
        x = 0;
        prePosts = [];
        YsL = []; 
        YsR = [];
        legendNames = {};
        for prePostNum = 1:length(prePostsFields)
            prePost = prePostsFields{prePostNum};
            trialNames = fieldnames(allDataStruct.(intervention_field_name).(speedName).(prePost).Trials);                          
            x = x+1; 
            for trialNum = 1:length(trialNames)
                trialName = trialNames{trialNum};
                gaitCycleNames = fieldnames(allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles);                 
                for cycleNum = 1:length(gaitCycleNames)
                    cycleName = gaitCycleNames{cycleNum};
                    cycleData = allDataStruct.(intervention_field_name).(speedName).(prePost).Trials.(trialName).GaitCycles.(cycleName).(plotFieldName);
                    legendName = [trialName ' ' cycleName];
                    prePosts = [prePosts; {prePost}];
                    YsL = [YsL; cycleData.L];
                    YsR = [YsR; cycleData.R];
                    legendNames = [legendNames; {legendName}];
                end
            end
        end
        Xs = NaN(size(prePosts));
        preIdx = ismember(prePosts, 'PRE');
        postIdx = ismember(prePosts, 'POST');
        Xs(preIdx) = 1;
        Xs(postIdx) = 2;
        sL = swarmchart(Xs, YsL,'filled');
        sR = swarmchart(Xs, YsR,'filled');
        sL.DataTipTemplate.DataTipRows(end+1) = [dataTipTextRow('Name', legendNames)];
        sR.DataTipTemplate.DataTipRows(end+1) = [dataTipTextRow('Name', legendNames)];
        xlim([0.5 2.5]);
        maxValue = max([YsL; YsR]);
        ylim([0, maxValue * 1.10]);
        xticks([1 2]);
        xticklabels({'Pre','Post'});
        ylabel(figName);
        title([figName ': ' intervention_field_name ' ' speedName ' All Trials Gait Cycles']);
        legend({'L','R'});
    end
end