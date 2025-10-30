function [scalarColumnNames] = getScalarColumnNames(tableIn)

%% PURPOSE: GET THE COLUMN NAMES FOR COLUMNS THAT ARE SCALAR VALUES (i.e. exportable to Excel)
% Inputs:
% tableIn: The table of data to get the scalar column names from
%
% Outputs:
% scalarColumnNames: The column names for scalar data
%
% NOTE: To be returned here, the data must be either a scalar numeric/char, 
% or a scalar struct with fields that are scalar numeric/char

scalarColumnNames = {};
allColumnNames = tableIn.Properties.VariableNames;
for i = 1:length(allColumnNames)
    currColData = tableIn.(allColumnNames{i});
    isScalar = true;
    for j = 1:length(currColData)
        currData = currColData(j);
        if iscell(currData)
            currData = currData{1};
        end
        if ~isscalar(currData)
            isScalar = false;
        end
        if isstruct(currData)
            fldNames = fieldnames(currData);
            for fldNum = 1:length(fldNames)
                if ~(isscalar(currData.(fldNames{fldNum})) && ~isstruct(currData.(fldNames{fldNum})))
                    isScalar = false;
                    break;
                end
            end
        end
        if ~isScalar
            break;
        end
    end
    if isScalar
        scalarColumnNames = [scalarColumnNames; allColumnNames(i)];
    end
end

catTable = copyCategorical(tableIn);
scalarColumnNames(ismember(scalarColumnNames, catTable.Properties.VariableNames)) = [];