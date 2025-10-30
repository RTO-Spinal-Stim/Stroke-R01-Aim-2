function [grTable] = correctGRTrialNumbersWhenLessThan3(grTable, otherTables)

%% PURPOSE: GAITRITE ALWAYS HAS INCREMENTING TRIAL NUMBERS (E.G. [1, 2]) BUT THAT MAY NOT
%% MATCH THE OTHER HARDWARES' TRIAL NUMBERS (E.G. [1, 3])
% Inputs:
% grTable: The GaitRite data table. Each row is one trial.
% otherTables: Cell array of tables for other hardware(s)
%
% Outputs:
% grTable: The GaitRite data table with modified trial numbers

catVarsNoSubset = {'Trial'};

grTableCategorical = copyCategorical(grTable);
grTableCategoricalSubset = grTableCategorical;
grTableCategoricalSubset(:, catVarsNoSubset) = [];
uniqueCombs = unique(grTableCategoricalSubset, 'rows', 'stable');
for i = 1:height(uniqueCombs)
    currComb = uniqueCombs(i,:);
    currRowsIdx = tableContains(grTableCategorical, currComb);
    
    % Check the trial numbers are all the same
    trialNums = cell(length(otherTables),1);
    for tableNum = 1:length(otherTables)
        currTable = otherTables{tableNum};
        trialNums{tableNum} = currTable.Trial(currRowsIdx);
    end

    trialNumsRef = trialNums{1};
    for tableNum = 2:length(trialNums)
        assert(isequal(trialNumsRef, trialNums{tableNum}));
    end

    % Modify the GaitRite trial numbers if fewer than 3
    if length(trialNumsRef) < 3
        grTable.Trial(currRowsIdx) = trialNumsRef;
    end

end