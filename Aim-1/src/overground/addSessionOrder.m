function [tableOut] = addSessionOrder(tableIn, tepsLog, sessionNumberColName, sessionNameColName, tableInColName, colNameToTheLeft)

%% PURPOSE: ADD THE SESSION NUMBER TO THE TABLE.
% Inputs:
% tableIn: The table of input data
% tepsLog: The table listing the subject, session numbers, and session names
% sessionNumberColName: The order in which each session was performed
% sessionNameColName: The name of the session
% tableInColName: The column name of the input data table to get the session name from
% colNameToTheLeft: The column name of the output data table that should be
% the left neighbor of the session order column
%
% Outputs:
% tableOut: The output data table

disp('Adding session order to table');

% Prep the output variable
tableOut = tableIn;
tableOut.(sessionNumberColName) = NaN(height(tableOut),1);

% Remove the unneeded columns from tableIn
allColNames = tableIn.Properties.VariableNames;
removeColNames = allColNames(~ismember(allColNames, {'Subject', tableInColName}));
tableInRemoved = removevars(tableIn, removeColNames);
varNames = tepsLog.Properties.VariableNames;
for i = 1:width(tepsLog)
    tepsLog.(varNames{i}) = categorical(tepsLog.(varNames{i}));
end

% Add the session number from each row of the TEPs log.
for i = 1:height(tepsLog)
    tmpTable = table;
    tmpTable.Subject = tepsLog.Subject(i);    
    tmpTable.(tableInColName) = tepsLog.(sessionNameColName)(i);

    sessionRowsIdx = ismember(tableInRemoved, tmpTable, 'rows');
    tableOut.(sessionNumberColName)(sessionRowsIdx) = double(tepsLog.(sessionNumberColName)(i));
end

tableOut = movevars(tableOut, sessionNumberColName, 'After', colNameToTheLeft);
tableOut.(sessionNumberColName) = categorical(tableOut.(sessionNumberColName));