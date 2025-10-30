function [aggStruct] = aggStructData(dataTable, dataColName, prefix)

%% PURPOSE: AGGREGATE A MATRIX ACROSS MULTIPLE TRIALS/GAIT CYCLES.
% Inputs:
% dataTable: The table to aggregate a subset of.
% dataColName: The field name to aggregate. Data in this field is a struct
% prefix: The prefix to aggregate by.
%
% Outputs: A struct with fields that are NxM, where N is the number of rows
% matching the prefix, and M is the lengths of the data in each field (all
% matching lengths)

dataTableIdx = tableContains(dataTable, prefix);
dataTableToAverage = dataTable(dataTableIdx,:);

aggStruct = struct;
for i = 1:height(dataTableToAverage)
    currData = dataTableToAverage.(dataColName)(i);
    fieldNames = fieldnames(currData);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};
        if ~isfield(aggStruct, fieldName)
            aggStruct.(fieldName) = [];
        end
        aggStruct.(fieldName) = [aggStruct.(fieldName); currData.(fieldName)];
    end        
end