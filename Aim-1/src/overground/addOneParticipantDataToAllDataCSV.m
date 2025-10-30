function [] = addOneParticipantDataToAllDataCSV(participantTable, allDataTablePath)

%% PURPOSE: ADD ONE PARTICIPANT'S DATA TO THE CSV FILE WITH ALL PARTICIPANT'S DATA.
% Inputs:
% participantTable: The table of one participant's data
% allDataTablePath: The path to the CSV file

catTable = copyCategorical(participantTable);
catVars = catTable.Properties.VariableNames;

% Load the table of all the data
if isfile(allDataTablePath)
    allDataTable = readtable(allDataTablePath);
    for i = 1:length(catVars)
        allDataTable.(catVars{i}) = categorical(allDataTable.(catVars{i}));
    end
else
    allDataTable = table;
end

% Remove the non-scalar column names
scalarColumnNames = getScalarColumnNames(participantTable);
participantTableScalar = removevars(participantTable, ~ismember(participantTable.Properties.VariableNames, [scalarColumnNames', catTable.Properties.VariableNames]));

% Remove the data that already exists that's being overwritten.
if height(allDataTable) > 0
    allDataTableCat = copyCategorical(allDataTable);
    participantTableScalarCat = copyCategorical(participantTableScalar);
    existingNameRowsIdx = ismember(allDataTableCat, participantTableScalarCat, 'rows');
    allDataTable(existingNameRowsIdx,:) = [];
end

% Append the participant data to the all data table, ensuring it's in the
% proper order.
allDataTable = addToTable(allDataTable, participantTableScalar);
allDataTable = sortrows(allDataTable, catVars);

% Write the table back to the CSV
writetable(allDataTable, allDataTablePath);