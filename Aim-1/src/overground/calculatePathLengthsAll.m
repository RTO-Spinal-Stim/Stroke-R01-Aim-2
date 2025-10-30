function [pathLengthsTable] = calculatePathLengthsAll(tableIn, colNameIn, colNameSuffix, sidePrefixes)

%% PURPOSE: CALCULATE THE PATH LENGTH OF A TIMESERIES
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct.
% colNameSuffix: The suffix of the column name to store the path length data
% sidePrefixes: Cell array of the single char prefixes to use in the
% columns. Default: {'L','R'} for left & right. Could also be {'A','U'} for
% affected and unaffected, or other
%
% Outputs:
% pathLengthsTable: The table with the computed path length data

disp('Calculating timeseries path lengths');

if ~exist('sidePrefixes','var')
    sidePrefixes = {'L','R'};
end

pathLengthsTable = copyCategorical(tableIn);
for i = 1:height(tableIn)

    data = tableIn.(colNameIn)(i);

    if ~isstruct(data)
        error(['Not a struct! ' colNameIn ' ' char(tableIn.Name{i})]);
    end

    structFieldNames = fieldnames(data);
    for fieldNum = 1:length(structFieldNames)
        fieldNameOrig = structFieldNames{fieldNum};
        fieldName = fieldNameOrig;
        if startsWith(fieldNameOrig,sidePrefixes)
            firstLetter = fieldNameOrig(1);
            fieldName = fieldNameOrig(2:end);
        end
        currData = data.(fieldNameOrig);
        colName = [firstLetter '_' fieldName '_' colNameSuffix];        
        if isempty(currData) || all(isnan(currData))
            pathLengthsTable.(colName)(i) = NaN;
            continue;
        end
        pathLengthsTable.(colName)(i) = calculatePathLength(currData);
    end
end

end

function [pathLength] = calculatePathLength(data)

%% PURPOSE: PERFORM THE PATH LENGTH CALCULATION
% Inputs:
% data: Timeseries vector
%
% Outputs:
% pathLength: The scalar length of the timeseries

dy = diff(data);

segment_lengths = sqrt(dy.^2);
pathLength = sum(segment_lengths) / length(data);

end