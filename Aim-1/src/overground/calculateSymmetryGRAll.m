function [symTable] = calculateSymmetryGRAll(tableIn, dataColNames, dataColNamesOut, lrIdxColName, startIdx, endIdx, formulaNum)

%% PURPOSE: CALCULATE SYMMETRY VALUES FOR THE SPECIFIED GAITRITE MEASURES ONLY.
% Inputs:
% tableIn: The table of data
% dataColNames: Cell array of column names to compute symmetry for
% dataColNamesOut: Cell array of column names to store the symmetry values
% lrIdxColName: The column name containing the boolean for L/R
% startIdx: Vector of doubles specifying which value to process first
% endIdx: Vector of doubles specifying which value to end processing at
% formulaNum: Scalar double specifying which symmetry formula to use.

disp('Calculating symmetry indices for GaitRite');

if ~exist('endIdx','var')
    endIdx = repmat(-1, 1, length(startIdx));
end

if ~exist('formulaNum','var')
    formulaNum = 3;
end

if ~iscell(dataColNames)
    dataColNames = {dataColNames};
end

lengths = [length(dataColNames), length(startIdx), length(endIdx), length(dataColNamesOut)];
if ~all(diff(lengths) == 0)
    error('Lengths of dataColNames, startIdx, and/or endIdx arguments do not all match');
end

symTable = table;
for i = 1:height(tableIn)
    tmpTable = table;
    tmpTable.Name = tableIn.Name(i);
    for colNum = 1:length(dataColNames)
        dataColName = dataColNames{colNum};
        dataColNameOut = dataColNamesOut{colNum};
        tmpOut = calculateSymmetryGR(tableIn.(dataColName){i}, tableIn.(lrIdxColName){i}, startIdx(colNum), endIdx(colNum), formulaNum);
        tmpTable.(dataColNameOut) = {tmpOut}; % So everything in the table is a scalar.
    end
    symTable = [symTable; tmpTable];
end