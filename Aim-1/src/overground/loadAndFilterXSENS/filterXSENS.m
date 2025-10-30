function [tableOut] = filterXSENS(tableIn, colNameToFilter, filteredColName, filterConfig, Fs)

%% PURPOSE: FILTER THE LOADED XSENS DATA.
% Inputs:
% tableIn: The table of input data
% colNameToFilter: The column name of the data to filter
% filteredColName: The column name of the filtered data
% config: The config struct for filtering
% Fs: Sampling frequency of the XSENS data
%
% Outputs:
% tableOut: The table of filtered data

disp('Filtering XSENS');

tableOut = copyCategorical(tableIn);

%% Configuration
fc = filterConfig.LOWPASS_CUTOFF;
n = filterConfig.LOWPASS_ORDER;
[b, a] = butter(n,fc/(Fs/2),'low');

%% Filter the data
for i = 1:height(tableIn)

    loaded_data = tableIn.(colNameToFilter)(i);
    colNamesFieldNames = fieldnames(loaded_data);
    filtered_data = struct();
    for colNum = 1:length(colNamesFieldNames)
        colNameFieldName = colNamesFieldNames{colNum};
        filtered_data.(colNameFieldName) = filtfilt(b, a, loaded_data.(colNameFieldName));
    end

    tableOut.(filteredColName)(i) = filtered_data;    

end