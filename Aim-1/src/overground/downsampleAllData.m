function [downsampledTable] = downsampleAllData(allDataTable, colNameToDownsample, colNameDownsampled, n_points)

%% PURPOSE: DOWNSAMPLE THE DATA FOR ALL TRIALS/GAIT CYCLES. THE DATA TO DOWNSAMPLE IS A STRUCT, WHERE EACH FIELD IS ONE SIGNAL.
% Inputs:
% allDataTable: Each row is one trial or gait cycle.
% colNameToDownsample: The column name for the data to be downsampled.
% n_points: Number of points to downsample the timeseries to.
%
% Outputs:
% downsampledTable: Table with the downsampled data, one row per trial or
% gait cycle.

disp(['Downsampling the data within each gait cycle to ' num2str(n_points) ' points']);

downsampledTable = copyCategorical(allDataTable);
for i = 1:height(allDataTable)
    dataToDownsample = allDataTable.(colNameToDownsample)(i);
    downsampledTable.(colNameDownsampled)(i) = downsampleData(dataToDownsample, n_points);
end