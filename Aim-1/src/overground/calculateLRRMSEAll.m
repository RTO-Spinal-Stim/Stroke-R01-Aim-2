function [rmseTable] = calculateLRRMSEAll(tableIn, colNameIn, colNameSuffix, sidePrefixes)

%% PURPOSE: COMPUTE RMSE BETWEEN L & R FIELDS OF A STRUCT. 
% NOTE: The RMSE is computed between the i'th gait cycle of one side and
% the i+1'th gait cycle (corresponding to the other side). Currently, the
% table of input data already matches alternating gait cycles into each row.
%
% Inputs:
% tableIn: The input data table
% colNameIn: The column name of the input data. This should be a struct
% which gait events are L vs. R
% colNameSuffix: The suffix of the column name to store the computed data
% sidePrefixes: Cell array of the single char prefixes to use in the
% columns. Default: {'L','R'} for left & right. Could also be {'A','U'} for
% affected and unaffected, or other
%
% Outputs:
% rmseTable: The table with the computed RMSE data

disp('Calculating RMSE');

if ~exist('sidePrefixes','var')
    sidePrefixes = {'L','R'};
end

firstSidePrefix = sidePrefixes{1};
secondSidePrefix = sidePrefixes{2};

rmseTable = table;
catTable = copyCategorical(tableIn);
for i = 1:height(tableIn)
    tmpTable = catTable(i,:);

    data = tableIn.(colNameIn)(i);

    if ~isstruct(data)
        error(['Not a struct! ' colNameIn ' ' char(tableIn.Name{i})]);
    end

    % Get all of the field names, removing the L & R prefixes
    structFieldsLR = fieldnames(data);
    structFieldsNoSides = {};
    for fieldNum = 1:length(structFieldsLR)
        fieldName = structFieldsLR{fieldNum}(2:end);
        if ~ismember(fieldName, structFieldsNoSides)
            structFieldsNoSides = [structFieldsNoSides; {fieldName}];
        end
    end

    for fieldNum = 1:length(structFieldsNoSides)
        fieldName = structFieldsNoSides{fieldNum};
        fieldNameSide1 = [firstSidePrefix fieldName];
        fieldNameSide2 = [secondSidePrefix fieldName];
        fieldNameStore = [fieldName '_' colNameSuffix];
        % There is one more L or R gait cycle vs. the other side.
        if isempty(data.(fieldNameSide1)) || isempty(data.(fieldNameSide2))
            tmpTable.(fieldNameStore) = NaN;
            continue;
        end
        difference = data.(fieldNameSide1) - data.(fieldNameSide2);
        squared_diff = difference.^2;
        mean_squared_diff = mean(squared_diff);
        rmseValue = sqrt(mean_squared_diff);        
        tmpTable.(fieldNameStore) = rmseValue;
    end

    rmseTable = [rmseTable; tmpTable];
end