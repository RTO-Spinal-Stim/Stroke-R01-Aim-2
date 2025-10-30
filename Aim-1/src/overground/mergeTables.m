function [mergedTable] = mergeTables(grTable, cycleTable, colNamesToMergeBy)

%% PURPOSE: MERGE THE GAITRITE TABLE AND CYCLE TABLE.
% Inputs:
% grTable: Each row is one row of the GaitRite data
% cycleTable: Each row is one gait cycle
% colNamesToMergeBy: Cell array of the columns that are being merged (e.g.
% 'GaitRiteRow' and 'Cycle'). The first element is for the grTable, 
% the second element is the column name in the cycleTable.
% NOTE: All of the other factor columns should
% be to the left of the colNamesToMergeBy columns.
%
% Outputs:
% mergedTable: Each row is one gait cycle
%
% NOTE: Removes the first two gait cycles from each trial in the cycleTable
% to match to the grTable

disp('Merging GaitRite and cycle tables');

if height(grTable) <= height(cycleTable)
    error('GaitRite table must have more rows than the cycle table!');
end

% Check the setup of the two tables.
grVarNames = grTable.Properties.VariableNames;
cycleVarNames = cycleTable.Properties.VariableNames;
grColIdx = ismember(grVarNames, colNamesToMergeBy);
cycleColIdx = ismember(cycleVarNames, colNamesToMergeBy);

if ~any(grColIdx) || ~any(cycleColIdx)
    error('Missing the specified colNamesToMergeBy columns in one or both tables');
end

grCatTable = copyCategorical(grTable);
cycleCatTable = copyCategorical(cycleTable);
grCatVars = grCatTable.Properties.VariableNames;
cycleCatVars = cycleCatTable.Properties.VariableNames;

if ~isequal(sort(grCatVars), sort(cycleCatVars))
    error('The factor column names are not identical');
end

catVars = grCatVars;
catVars(ismember(catVars, 'StartFoot')) = [];

mergedTable = table;

% Identify any column names to the right of the factors that are shared
% across both tables, so we can remove duplicates.
grVarNames = grVarNames(~ismember(grVarNames, grCatVars));
cycleVarNames = cycleVarNames(~ismember(cycleVarNames, cycleCatVars));
sharedVarNames = cycleVarNames(ismember(cycleVarNames, grVarNames));

% Get all of the unique trials from the table.
trialNames = unique(cycleTable(:, colNamesToMergeBy), 'rows', 'stable');
for i = 1:height(trialNames)

    % Isolate only the rows of the current trial in each table
    currTrialIdxGR = tableContains(grTable, trialNames(i,:));
    currTrialIdxCycle = tableContains(cycleTable, trialNames(i,:));
    currTrialCycle = cycleTable(currTrialIdxCycle, :);
    currTrialGR = grTable(currTrialIdxGR, grVarNames);    

    % Remove shared variables from the cycle table.
    currTrialGR = removevars(currTrialGR, sharedVarNames);

    assert(height(currTrialGR) == height(currTrialCycle) + 2,'Wrong number of gait cycles relative to the number of GaitRite rows! Failed to merge tables.');

    % Horizontally concatenate the two tables so all of the data is in tmpTable.
    % tmpTable = join(currTrialCycle, currTrialGR(3:end,:), 'Keys', catVars);    
    tmpTable = [currTrialCycle, currTrialGR(3:end,:)];

    % Vertically concatenate each trial
    mergedTable = [mergedTable; tmpTable];

end