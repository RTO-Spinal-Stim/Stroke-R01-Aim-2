function [extracted_data] = loadXSENSOneFile(xsensFilePath, colNamesStruct)

%% PURPOSE: PREPROCESS XSENS DATA
% Inputs:
% xsensFilePath: The path to the XSENS file
% colNamesStruct: The struct of column names. Fields are field names to
% store the data to, values are the names of the columns in the Excel
% sheet.
%
% Outputs:
% extracted_data: The data loaded from the Excel file.

%% Load the data
[raw_data, header_row, cell_data] = xlsread(xsensFilePath, 'Joint Angles XZY');

%% Get column indices
colNamesFieldNames = fieldnames(colNamesStruct);
indices = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    indices.(colNameFieldName) = ismember(header_row, colNamesStruct.(colNameFieldName));
end

%% Extract the data
nanIdx = isnan(raw_data(:,indices.(colNameFieldName)));

% Perform the data extraction
extracted_data = struct();
for i = 1:length(colNamesFieldNames)
    colNameFieldName = colNamesFieldNames{i};
    extracted_data.(colNameFieldName) = raw_data(~nanIdx, indices.(colNameFieldName));
end