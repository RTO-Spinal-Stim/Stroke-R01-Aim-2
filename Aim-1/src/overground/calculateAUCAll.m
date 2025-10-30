function [aucTable] = calculateAUCAll(tableIn, colNameIn, columnNameSuffix)

%% PURPOSE: CALCULATE THE AREA UNDER THE CURVE (AUC) FOR THE SPECIFIED COLUMN.
% Inputs:
% tableIn: The table of data
% colNameIn: The column to compute the AUC for. Data should be a struct.
% columnNameSuffix: The suffix for the column name to store the AUC in.
% sidePrefixes: Cell array of the single char prefixes to use in the
% columns. Default: {'L','R'} for left & right. Could also be {'A','U'} for
% affected and unaffected, or other
%
% Outputs:
% aucTable: The table with the computed AUC data

disp('Calculating area under the curve (AUC)');

if ~exist('sidePrefixes','var')
    sidePrefixes = {'L','R'};
end

aucTable = copyCategorical(tableIn);
for i = 1:height(tableIn)
    currData = tableIn.(colNameIn)(i);
    structFields = fieldnames(currData);
    for fieldNum = 1:length(structFields)
        fieldNameOrig = structFields{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,sidePrefixes)
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        storeFieldName = [firstLetter '_' fieldName '_' columnNameSuffix];
        if isempty(currData.(fieldNameOrig)) || all(isnan(currData.(fieldNameOrig)))
            aucTable.(storeFieldName)(i) = NaN;
        else
            aucTable.(storeFieldName)(i) = trapz(currData.(fieldNameOrig));
        end
    end
end