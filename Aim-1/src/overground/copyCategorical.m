function [categoricalColumnsTable] = copyCategorical(tableIn)

%% PURPOSE: COPY ONLY THE CATEGORICAL COLUMNS FROM A TABLE TO A NEW TABLE
% Inputs:
% tableIn: The table of input data
%
% Outputs:
% categoricalColumnsTable: The table of categorical data only

categoricalVarNames = tableIn.Properties.VariableNames(vartype('categorical'));
categoricalColumnsTable = tableIn(:, categoricalVarNames);