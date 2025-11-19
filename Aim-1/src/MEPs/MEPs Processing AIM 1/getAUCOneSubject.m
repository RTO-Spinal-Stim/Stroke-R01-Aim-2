function [resultTable] = getAUCOneSubject(config, tableIn)

%% PURPOSE: CALCULATE THE AUC FOR ONE SUBJECT'S TEPs
% Inputs:
% config: Configuration struct
% tableIn: The table containing data from previous steps
%
% Outputs:
% resultTable:
resultTable = table;
for i = 1:height(tableIn)
    fileTable = getAUCOneFile(config, tableIn(i,:));
    resultTable = [resultTable; fileTable];
end