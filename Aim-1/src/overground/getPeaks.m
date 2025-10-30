function [tableOut] = getPeaks(tableIn, colName, colNameOutSuffix, maxMin, indexPeak)

%% PURPOSE: IDENTIFY WHEN THE PEAKS OCCUR WITHIN EACH TIMESERIES.
% Inputs:
% tableIn: The input data table
% colName: The column name to analyze
% colNameOutSuffix: The suffix of the output column name
% maxMin: Specify whether to take max, min, or both
% indexPeak: Specify whether to find the peak index, magnitude, or both
%
% Outputs:
% tableOut: The output data table with peaks column added

disp('Finding indices and values of peaks in the data');

catTable = copyCategorical(tableIn);
tableOut = table;

if ~iscell(maxMin)
    maxMin = {maxMin};
end
maxMin = lower(maxMin);
if any(~ismember(maxMin, {'max','min'}))
    error('Wrong entries in the maxMin vector. Valid entries are {"max", "min"}');
end

indexPeak = lower(indexPeak);
indexStr = 'index';
peakStr = 'peak';
if any(~ismember(indexPeak, {indexStr,peakStr}))
    error('Wrong entries in the indexPeaks vector. Valid entries are {"index", "peak"}');
end

for i = 1:height(tableIn)
    rowData = tableIn.(colName)(i);
    fldNames = fieldnames(rowData);

    peaksData.Max = struct;
    indexData.Max = struct;
    peaksData.Min = struct;
    indexData.Min = struct;
    tmpTable = catTable(i,:);
    for fldNum = 1:length(fldNames)
        fldName = fldNames{fldNum};
        currData = rowData.(fldName);
        % Make it a column vector
        if size(currData,2) > size(currData,1)
            currData = currData';
        end
        [maxVal, maxIdx] = max(currData,[],1,'omitnan');
        [minVal, minIdx] = min(currData,[],1,'omitnan');

        side = fldName(1);
        streamName = fldName(2:end);
        prefix = [side '_' streamName];
        
        if ismember({'max'}, maxMin)
            if ismember({indexStr}, indexPeak)
                tmpTable.([prefix '_MaxPeakIndex_' colNameOutSuffix]) = maxIdx;    
            end
            if ismember({peakStr}, indexPeak)
                tmpTable.([prefix '_MaxPeakValue_' colNameOutSuffix]) = maxVal;
            end
        end
        if ismember({'min'}, maxMin)
            if ismember({indexStr}, indexPeak)
                tmpTable.([prefix '_MinPeakIndex_' colNameOutSuffix]) = minIdx;
            end
            if ismember({peakStr}, indexPeak)
                tmpTable.([prefix '_MinPeakValue_' colNameOutSuffix]) = minVal;
            end
        end
    end
    tableOut = [tableOut; tmpTable];
end