function [tableOut] = distributeGaitRiteDataToSeparateTable(grTable, colNamesToRemove)

%% PURPOSE: PARSE THE GAITRITE DATA INTO THE CYCLES TABLE
% Inputs:
% grTable: The table with GaitRite data (each row is one walk)
% cycleTable: The table with the parsed gait cycle data (each row is one
% gait cycle)
%
% Outputs:
% cycleTable: The output table with one row per gait cycle
%
% HOW THIS WORKS:
% Step Lengths: Computed based on the front of the two feet involved in a
% step. Therefore, the first heel strike always results in a step length of
% 0 (should be NaN), because there's no preceding foot fall.

disp('Distributing GaitRite data to each row')

tableOut = table;

%% Remove the scalar columns from the grTable
scalarColumnNames = getScalarColumnNames(grTable);
grTable = removevars(grTable, scalarColumnNames);

colNameAllIdx = 'All_Idx_GR';
colNameLIdx = 'L_Idx_GR';
colNameRIdx = 'R_Idx_GR';

if ~exist('colNamesToRemove','var')
    colNamesToRemove = {colNameAllIdx};
end

%% Get the column names that start with the prefix for each side, e.g. "L_" and "R_"
columnNames = grTable.Properties.VariableNames;
colNamesAll = columnNames(contains(columnNames, 'All_'));
colNamesAll(ismember(colNamesAll, colNamesToRemove)) = [];

grTableCategorical = copyCategorical(grTable);

%% Iterate over each trial
for i = 1:height(grTable)

    allIdx = grTable.(colNameAllIdx){i};    
    rowCategorical = grTableCategorical(i,:);
    lIdx = grTable.(colNameLIdx){i};
    rIdx = grTable.(colNameRIdx){i};

    assert(length(lIdx) == length(allIdx) && length(rIdx) == length(allIdx));

    trialTable = repmat(rowCategorical,length(allIdx),1);

    % Assign the data to each cycle
    for rowNum = 1:length(allIdx)

        if lIdx(rowNum) == 1
            suffix = 'L';
        elseif rIdx(rowNum) == 1
            suffix = 'R';
        end

        if rowNum < 10
            rowNumStr = ['0' num2str(rowNum)];
        else
            rowNumStr = num2str(rowNum);
        end
        trialTable.GaitRiteRow(rowNum) = string(rowNumStr);
        trialTable.StartFoot(rowNum) = string(suffix);
        % tmpTable.Name = convertCharsToStrings([rowCategorical '_GaitRiteRow' rowNumStr '_' suffix]);

        for j = 1:length(colNamesAll)
            colName = colNamesAll{j};
            currData = grTable.(colName){i};
            colName = colName(5:end);
            
            trialTable.(colName)(rowNum) = currData(rowNum);
        end        
    end
    tableOut = [tableOut; trialTable];
end

tableOut.GaitRiteRow = categorical(tableOut.GaitRiteRow);
tableOut.StartFoot = categorical(tableOut.StartFoot);