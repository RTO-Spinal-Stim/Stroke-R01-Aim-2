function [mergedTable] = addToTable(existingTable, newTable)

%% PURPOSE: ADD THE NEW TABLE IN TO THE EXISTING TABLE USING A LEFT JOIN
% https://www.mathworks.com/help/matlab/ref/table.join.html
% Inputs:
% existingTable: The table for which columns are being added
% newTable: The table to add the columns from
%
% Outputs:
% mergedTable: The merged table

if height(existingTable) == 0
    mergedTable = newTable;
    return;
end

% Check that the categorical rows in the existing table are unique
existingTableCat = copyCategorical(existingTable);
uniqueExistingCat = unique(existingTableCat, 'rows', 'stable');
assert(height(uniqueExistingCat) == height(existingTable), 'The categorical variables in the existing table are not unique!');

% Check that the categorical rows in the new table are unique
newTableCat = copyCategorical(newTable);
uniqueNewCat = unique(newTableCat, 'rows', 'stable');
assert(height(uniqueNewCat) == height(newTable), 'The categorical variables in the new table are not unique!');

existingVarNames = existingTable.Properties.VariableNames;
newVarNames = newTable.Properties.VariableNames;

existingCategoricalVarNames = existingTable.Properties.VariableNames(vartype('categorical'));
newCategoricalVarNames = newTable.Properties.VariableNames(vartype('categorical'));

%% If the categorical columns are different but all column names are the same, vertically concatenate.
if all(ismember(existingVarNames, newVarNames)) && length(existingVarNames) == length(newVarNames)
    if isequal(existingCategoricalVarNames, newCategoricalVarNames)
        mergedTable = [existingTable; newTable];
        mergedTableCat = copyCategorical(mergedTable);
        uniqueMergedCat = unique(mergedTableCat, 'rows', 'stable');
        assert(height(uniqueMergedCat) == height(mergedTable), 'The categorical variables in the merged table are not unique!');
        return;
    end
end

categoricalVars = existingCategoricalVarNames;

%% Otherwise, perform the horizontal concatenation
assert(height(newTable) == height(existingTable),'Both tables must have the same number of rows for horizontal concatenation!');
mergedTable = join(newTable, existingTable, 'Keys', categoricalVars, ...
        'LeftVariables', newVarNames, ...
        'RightVariables', setdiff(existingVarNames, categoricalVars),...
        'KeepOneCopy', newVarNames);

newVarNamesToAdd = setdiff(newVarNames, categoricalVars);
finalColumnOrder = [existingVarNames, setdiff(newVarNamesToAdd, existingVarNames)];
mergedTable = mergedTable(:, finalColumnOrder);

for colNum = 1:length(categoricalVars)
    mergedTable.(categoricalVars{colNum}) = string(mergedTable.(categoricalVars{colNum}));
    mergedTable.(categoricalVars{colNum}) = categorical(mergedTable.(categoricalVars{colNum}));
end

% Check that the categorical rows are unique
mergedTableCat = copyCategorical(mergedTable);
uniqueMergedCat = unique(mergedTableCat, 'rows', 'stable');
assert(height(uniqueMergedCat) == height(mergedTable), 'The categorical variables in the merged table are not unique!');