function [magsDiffsTable] = magsDursDiffsLR_All(dataTable, spmColName, averagedColName, storeColName)

%% PURPOSE: COMPUTE THE MAGNITUDE & DURATIONS OF DIFFERENCES OBTAINED FROM SPM
% Inputs:
% dataTable: Each row of the dataTable is one visit
% spmColName: The column name of the SPM results.
% averagedColName: The column name of the averaged data (1xN)
% storeColName: The column name to store the data to
%
% Outputs:
% magsDiffsTable: Each row is one visit.

disp('Calculating magnitude & durations of each side''s differences from SPM');

magsDiffsTable = table;
catTable = copyCategorical(dataTable);
for i = 1:height(dataTable)
    tmpTable = catTable(i,:);
    averageData = dataTable.(averagedColName)(i);
    spmData = dataTable.(spmColName)(i);
    [mags, durs] = mags_durs_diffsLR(spmData, averageData);
    tmpTable.([storeColName '_Mags']) = mags;
    tmpTable.([storeColName '_Durs']) = durs;
    magsDiffsTable = [magsDiffsTable; tmpTable];
end