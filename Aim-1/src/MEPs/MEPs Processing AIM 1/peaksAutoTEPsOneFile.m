function [resultTable] = peaksAutoTEPsOneFile(config, tableIn, columnName, fig)

%% PURPOSE: FIND PEAKS AUTOMATICALLY IN TEPs FOR ONE FILE.
% Inputs:
% config: The configuration struct
% tableIn: The table containing the data from previous steps
% columnName: The column name to find peaks in.
%
% Outputs:
% resultTable: The output

resultTable = table;

musclesDataIn = tableIn.(columnName);
muscleNames = fieldnames(musclesDataIn);
peaksConfig = config.PEAKS;
for i = 1:length(muscleNames)
    muscleName = muscleNames{i};    
    clf;
    hold on;
    set(fig,'Name',muscleName);
    muscleTable = peaksAutoTEPsOneMuscle(musclesDataIn.(muscleName), muscleName, peaksConfig.MIN_PEAK_PROMINENCE, peaksConfig.MIN_PEAK_HEIGHT, peaksConfig.MIN_PEAK_WIDTH);
    varNames = muscleTable.Properties.VariableNames;
    for varNum = 1:length(varNames)
        varName = varNames{varNum};
        if ~ismember(varName, resultTable.Properties.VariableNames)
            resultTable.(varName) = struct;
        end
        resultTable.(varName).(muscleName) = muscleTable.(varName);
    end
    sgtitle([tableIn.Name{1} ' ' muscleName],'Interpreter','none');    
    savePath = fullfile(config.PLOT_TROUBLESHOOT_FOLDER, [muscleName '_' tableIn.Name{1}]);
    fig.WindowState = 'maximized';
    saveas(fig, [savePath '.fig']);
    saveas(fig, [savePath '.png']);    
end