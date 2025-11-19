function [rmsTable] = calculateRMSAll(tableIn, colNameIn, colNameSuffix, sidePrefixes)

%% PURPOSE: CALCULATE THE RMS OF A TIMESERIES
% Inputs:
% tableIn: The input data table
% colNameIn: The column name to analyze. The data should be a struct.
% colNameSuffix: The suffix of the column name to store the RMS data
% sidePrefixes: Cell array of the single char prefixes to use in the
% columns. Default: {'L','R'} for left & right. Could also be {'A','U'} for
% affected and unaffected, or other
%
% Outputs:
% rmsTable: The table with the RMS data

disp('Calculating RMS');

if ~exist('sidePrefixes','var')
    sidePrefixes = {'L','R'};
end

rmsTable = copyCategorical(tableIn);
for i = 1:height(tableIn)  
    currData = tableIn.(colNameIn)(i);
    structFieldNames = fieldnames(currData);
    for fieldNum = 1:length(structFieldNames)
        fieldNameOrig = structFieldNames{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,sidePrefixes)
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        colName = [firstLetter '_' fieldName '_' colNameSuffix];
        if isempty(currData.(fieldNameOrig)) || all(isnan(currData.(fieldNameOrig)))
            rmsTable.(colName)(i) = NaN;
        else
            rmsTable.(colName)(i) = rms(currData.(fieldNameOrig));
        end
    end
end