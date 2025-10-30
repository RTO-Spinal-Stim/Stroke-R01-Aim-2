resultsTableAll = resultsTable;

resultsTable = resultsTableAll;

resultTable(resultTable.PulseNum <= 75) = [];

resultsTable = resultsTableAll(resultsTableAll.PulseNum > 75 & resultsTableAll.PulseNum <= 80,:);
resultsTable = resultsTableAll(resultsTableAll.PulseNum > 70 & resultsTableAll.PulseNum <= 75,:);
resultsTable = resultsTableAll(resultsTableAll.PulseNum > 65 & resultsTableAll.PulseNum <= 70,:);
resultsTable = resultsTableAll(resultsTableAll.PulseNum > 40 & resultsTableAll.PulseNum <= 45,:);
resultsTable = resultsTableAll(resultsTableAll.PulseNum == 31,:);

resultsTable = resultsTableAll;
resultsTable = resultsTableAll(resultsTableAll.PulseNum == 80,:);
removeIdx = false(height(resultsTable),1);
for i = 1:height(resultsTable)
    currDataValue = resultsTable.DataP2P(i);
    currLag = resultsTable.lag(i);
    currDataValueHasLagNeighbor = any(ismember(resultsTable.DataP2P, currDataValue) & (ismember(resultsTable.lag, currLag-1) | ismember(resultsTable.lag, currLag+1)));
    if ~currDataValueHasLagNeighbor
        removeIdx(i) = true;
    end
end
resultsTable(removeIdx,:) = [];

%% Get the DataP2P with the highest sum R^2
uniqueDataValues = unique(resultsTable.DataP2P,'stable');
R2sums = NaN(length(uniqueDataValues),1);
for i = 1:length(uniqueDataValues)
    currDataValue = uniqueDataValues(i);
    currDataIdx = ismember(resultsTable.DataP2P, currDataValue);
    R2_values = resultsTable.DataP2P(currDataIdx);
    R2sums(i) = sum(R2_values);
end

[~,maxR2idx] = max(R2sums);
maxR2DataP2P = uniqueDataValues(maxR2idx);