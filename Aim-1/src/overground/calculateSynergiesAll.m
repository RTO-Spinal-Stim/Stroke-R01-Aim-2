function [synergiesTable] = calculateSynergiesAll(dataTable, dataColName, fieldNames, VAFthresh, fieldNamePrefix)

%% PURPOSE: CALCULATE THE NUMBER OF MUSCLE SYNERGIES FOR ALL TRIALS/GAIT CYCLES
% Inputs:
% dataTable: Each row is one gait cycle
% dataColName: The column name to calculate the muscle synergies from.
% fieldNames: The names of the fields from the dataColName to calculate the
% muscle synergies from
% VAFthresh: The threshold for Variance Accounted For (VAF)
% fieldNamePrefix: Char to put at the beginning of the table field names, i.e. to
% indicate L vs. R, or both together, etc.
%
% Outputs:
% synergiesTable: Each row is one gait cycle.

disp('Computing the number of muscle synergies');

% Initialize the suffix
if ~exist('fieldNamePrefix','var')
    fieldNamePrefix = '';
end

% Make sure the suffix starts with '_' if it's not empty
if ~isempty(fieldNamePrefix) && ~isequal(fieldNamePrefix(end), '_')
    fieldNamePrefix = [fieldNamePrefix '_'];
end

catTable = copyCategorical(dataTable);
synergiesTable = table;
for i = 1:height(dataTable)
    currData = dataTable.(dataColName)(i);
    tmpTable = catTable(i,:);
    [nSynergies, VAFs, W, H] = calculateSynergies(currData, fieldNames, VAFthresh);
    tmpTable.([fieldNamePrefix 'NumSynergies']) = nSynergies;
    tmpTable.([fieldNamePrefix 'VAFs']) = {VAFs};
    tmpTable.([fieldNamePrefix 'W']) = {W};
    tmpTable.([fieldNamePrefix 'H']) = {H};
    synergiesTable = [synergiesTable; tmpTable];
end