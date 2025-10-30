function [tableOut] = splitTrialsByGaitCycle_NoMatching(tableIn, colNameToSplit, gaitEventsColName)

%% PURPOSE: SPLIT THE TRIALS BY GAIT CYCLE. IF THE GAIT CYCLE IS L TO L, IT IS MARKED AS "L", AND VICE VERSA
% Inputs:
% tableIn: The input data table
% colNameToSplit: The column name for the data to split
% gaitEventsColName: The column name for the gait events
%
% tableOut: The table of data split by gait cycles

disp('Segmenting the data by gait cycle WITHOUT matching');

tableOut = table;
catTable = copyCategorical(tableIn);
for i = 1:height(tableIn)
    
    LHS = tableIn.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
    RHS = tableIn.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes;
    allHS = sort([LHS; RHS]); % Get all of the heel strike events together
    allHS(isnan(allHS)) = []; % Remove NaN
    num_gait_cycles = length(allHS) - 2; % The number of gait cycles is two less than the total number of footfalls
    currData = tableIn.(colNameToSplit)(i);

    for cycleNum = 1:num_gait_cycles
        startHSIdx = allHS(cycleNum);
        fldNames = fieldnames(currData);
        % Get all of the data (L & R) from the current gait cycle
        for fldNum = 1:length(fldNames)
            fldName = fldNames{fldNum};
            cycleData.(fldName) = currData.(fldName)(allHS(cycleNum):allHS(cycleNum+2)-1);
        end
        if ismember(startHSIdx, LHS)
            startFoot = 'L';
        elseif ismember(startHSIdx, RHS)
            startFoot = 'R';
        end
        if cycleNum < 10
            cycleNumStr = ['0' num2str(cycleNum)];
        else
            cycleNumStr = num2str(cycleNum);
        end
        tmpTable = catTable(i,:);
        tmpTable.Cycle = string(cycleNumStr);
        tmpTable.StartFoot = string(startFoot);
        tmpTable.(colNameToSplit) = cycleData;

        tableOut = [tableOut; tmpTable];
    end

end

tableOut.Cycle = categorical(tableOut.Cycle);
tableOut.StartFoot = categorical(tableOut.StartFoot);