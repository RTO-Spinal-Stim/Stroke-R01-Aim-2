function [cycleTable] = splitTrialsByGaitCycleMatchingLR(trialTable, colNameToSplit, gaitEventsColName)

%% PURPOSE: SPLIT ALL TRIALS INTO THEIR CONSTITUENT GAIT CYCLES, MATCHING L & R DATA FROM L & R GAIT CYCLES INTO EACH GAIT CYCLE
% Inputs:
% trialTable: The input data table, where each row is one trial
% colNameToSplit: The column name of the data that will be split into each gait cycle
% gaitEventsColName: The column name for the gait events
%
% Outputs:
% cycleTable: The output table. Each row is one gait cycle
%
% NOTE: The data that is split into gait cycles is already staggered by L &
% R gait cycles. Therefore, gait cycle 1's L data is between the first two
% L heel strikes, and gait cycle 1's R data is between the first two R heel
% strikes.

disp('Splitting data by gait cycle');

cycleTable = table;
for i = 1:height(trialTable)
    LHS = trialTable.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
    RHS = trialTable.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes;
    [perGaitCycleStruct, maxNumCycles, startFoot] = splitTrialByGaitCycleMatchingLR(trialTable.(colNameToSplit)(i), LHS, RHS);

    %% Convert this format to be a table with one row per gait cycle, and a struct inside each row.
    tmpTable = table;
    fieldNames = fieldnames(perGaitCycleStruct);
    for cycleNum = 1:maxNumCycles
        cycleName = ['cycle' num2str(cycleNum)];
        cycleStruct = struct;
        for fieldNum=1:length(fieldNames)
            fieldName = fieldNames{fieldNum};
            cycleStruct.(fieldName) = perGaitCycleStruct.(fieldName){cycleNum};
        end
        tmpTable.Name = convertCharsToStrings([char(trialTable.Name(i)) '_' cycleName]);
        tmpTable.(colNameToSplit) = cycleStruct;
        tmpTable.StartFoot = startFoot(cycleNum);
        cycleTable = [cycleTable; tmpTable];
    end
end