function [resultTable] = peaksAutoTEPsOneSubject(config, tableIn, columnName)

%% PURPOSE: COMPUTE THE PEAKS FOR TEPs AUTOMATICALLY FOR ONE SUBJECT
% Inputs:
% config: The configuration struct
% tableIn: The table containing the data from previous steps
% columnName: The column name to find peaks in.
%
% Outputs:
% resultTable: The output

resultTable = table;
fig = figure;
for i = 1:height(tableIn)
    fileTable = peaksAutoTEPsOneFile(config, tableIn(i,:), columnName, fig);
    resultTable = [resultTable; fileTable];
end
close(fig);