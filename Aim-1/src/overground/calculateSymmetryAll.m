function [symmetryTable] = calculateSymmetryAll(tableIn, colNameSuffix, formulaNum, nonSubsetCatVars)

%% PURPOSE: CALCULATE THE SYMMETRY VALUES BETWEEN THE TWO COLUMNS.
% Inputs:
% tableIn: The table with the input data
% colNameSuffix: The suffix to append to the column names
% formulaNum: The number of the formula to use
% nonSubsetCatVars: The categorical variables to not include in the subsetting
%
% Outputs:
% symmetryTable: The table of computed symmetry values.

disp('Calculating symmetry indices');

if ~exist('formulaNum','var')
    %formulaNum = 2;
    formulaNum = 1;
end

if ~exist('levelNum','var')
    levelNum = 5;
end

catTable = copyCategorical(tableIn);
categoricalCols = catTable.Properties.VariableNames;
subsetCatVars = categoricalCols(~ismember(categoricalCols, nonSubsetCatVars));

colNames = tableIn.Properties.VariableNames;
colNames(ismember(colNames, categoricalCols)) = [];

symmetryTable = table;
for i = 1:height(tableIn)-1
    tmpTable = catTable(i,:);
    currName = catTable(i,subsetCatVars);
    nextName = catTable(i+1,subsetCatVars);
    if ~isequal(currName, nextName)
        continue;
    end
    
    for fieldNum = 1:length(colNames)
        colName = colNames{fieldNum};
        v1 = tableIn.(colName)(i);
        v2 = tableIn.(colName)(i+1);
        if iscell(v1)
            v1 = v1{1};
        end
        if iscell(v2)
            v2 = v2{1};
        end
        if isempty(v1) || isempty(v2)
            tmpOut = NaN;
        else
            tmpOut = calculateSymmetryTwoVectors(v1, v2, formulaNum);
        end
        if length(tmpOut) > 1
            tmpOut = {tmpOut};
        end
        tmpTable.([colName colNameSuffix]) = tmpOut;
    end

    symmetryTable = [symmetryTable; tmpTable];
end