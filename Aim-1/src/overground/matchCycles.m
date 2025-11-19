function [matchedTable] = matchCycles(tableIn)

%% PURPOSE: MATCH THE GAIT CYCLES' DATA TOGETHER
% Inputs:
% tableIn: The table of input data. Each row is one gait cycle's data, and
% the "Name" column should end with "L" or "R" to indicate which side gait
% cycle it is.
% startFootColName: The name of the column to store the L/R lead foot info
%
% Outputs:
% matchedTable: The table used for symmetry analysis, where each row is one
% matched gait cycle.

disp('Matching L & R gait cycles')

catTable = copyCategorical(tableIn);
trialLevelNum = length(catTable.Properties.VariableNames) - 2;
% Get the unique trial names
trialNamesToMatch = unique(catTable(:,1:trialLevelNum),'rows','stable');
cycleLevelNum = trialLevelNum + 1;
colNames = tableIn.Properties.VariableNames;
colNames(ismember(colNames,catTable.Properties.VariableNames)) = [];
matchedTable = table;
% Iterate over each trial
for i = 1:height(trialNamesToMatch)
    % Get all the rows matching this trial name
    matchRows = tableContains(tableIn, trialNamesToMatch(i,:));
    % matchRows = contains(tableIn.Name, trialNamesToMatch{i});
    % Filter the table for only the rows in this trial
    filteredTable = tableIn(matchRows,:);    

    % Iterate over each cycle in the trial
    for j = 1:height(filteredTable)-1
        currCycleRow = filteredTable(j,:);
        nextCycleRow = filteredTable(j+1,:);
        currCycleSide = char(currCycleRow.StartFoot); 
        nextCycleSide = char(nextCycleRow.StartFoot);                
        tmpTable = copyCategorical(currCycleRow);

        % Iterate over each column in the cycle
        for colNum = 1:length(colNames)
            colName = colNames{colNum};
            currColData = filteredTable.(colName)(j);
            if ~isstruct(currColData)
                continue;
            end
            tmpTable.(colName) = struct;
            fldNames = fieldnames(currColData);            
            for fldNum = 1:length(fldNames)
                fldName = fldNames{fldNum};
                % If this field is on the ipsilateral side of the current
                % gait cycle, use the data from the current gait cycle. If
                % contralateral, use the data from the next gait cycle.
                if startsWith(fldName, currCycleSide)
                    tmpTable.(colName).(fldName) = currCycleRow.(colName).(fldName);
                elseif startsWith(fldName, nextCycleSide)
                    tmpTable.(colName).(fldName) = nextCycleRow.(colName).(fldName);
                end
            end
        end
        matchedTable = [matchedTable; tmpTable];
    end
end