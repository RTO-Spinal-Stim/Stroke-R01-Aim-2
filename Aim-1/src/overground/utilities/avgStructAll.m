function [avgStructTable] = avgStructAll(dataTable, colNameToAverage, averagedColName, levelNum)

%% PURPOSE: AVERAGE THE DATA.
% Inputs:
% dataTable: The table containing all of the data. Each row is one entry.
% colNameToAverage: The column name to use for averaging.
% averagedColName: The column name to store the averages in.
% levelNum: The level to average within (counting backwards from the end)
%
% Output:
% avgStructTable: Each row is one struct, where each field has the averaged
% data

disp('Averaging the data within one visit');

if ~exist('levelNum','var')
    levelNum = 4;
end

catTable = copyCategorical(dataTable);
visitNames = unique(catTable(:,1:levelNum),'rows','stable');
avgStructTable = table;
for i = 1:height(visitNames)
    visitName = visitNames(i,:);
    avgStruct = struct;
    aggStruct = aggStructData(dataTable, colNameToAverage, visitName);
    fieldNames = fieldnames(aggStruct);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        avgStruct.(fieldName) = mean(aggStruct.(fieldName),1,'omitnan');
    end
    tmpTable = visitName;
    tmpTable.(averagedColName) = avgStruct;
    avgStructTable = [avgStructTable; tmpTable];
end