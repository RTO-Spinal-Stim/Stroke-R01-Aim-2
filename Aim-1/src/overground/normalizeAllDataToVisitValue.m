function [normalizedDataTable] = normalizeAllDataToVisitValue(dataTable, dataColName, visitTable, visitColName, normalizedDataColName, levelNum)

%% PURPOSE: NORMALIZE DATA IN A TRIAL OR GAIT CYCLE TO A PER-VISIT VALUE FROM THE VISIT TABLE.
% Inputs:
% dataTable: Each row is one trial or gait cycle
% dataColName: The column of the dataTable to normalize (struct with signals).
% visitTable: The visit table, each row is one visit.
% visitColName: The column name of the visit to normalize by (struct of peaks).
% normalizedDataColName: The column name to store the normalized data to.
% levelNum: The level of the Name column to segment by.
%
% Outputs:
% normalizedDataTable: The normalized data.

disp('Normalizing data to per-visit value');

normalizedDataTable = copyCategorical(dataTable);

for i = 1:height(dataTable)
    % Struct of signals for this trial
    dataToNormalize = dataTable.(dataColName)(i);

    % Match this trial’s visit (Subject+Intervention up to levelNum)
    visitName = dataTable(i, 1:levelNum);
    visitRowInVisitTable = tableContains(visitTable, visitName);
    assert(sum(visitRowInVisitTable) == 1, 'Visit row not found or not unique.');

    % Grab the struct of peak values for this visit
    visitDataCell = visitTable.(visitColName)(visitRowInVisitTable);
    if iscell(visitDataCell)
        visitData = visitDataCell{1};  % unwrap cell -> struct
    else
        visitData = visitDataCell;     % already a struct
    end

    % Normalize each field
    normalizedStruct = struct;
    fieldNames = fieldnames(dataToNormalize);
    for fieldNum = 1:length(fieldNames)
        fieldName = fieldNames{fieldNum};

        signal = dataToNormalize.(fieldName);  % 1x101 array
        peakVal = visitData.(fieldName);       % scalar max MVC

        % Protect against divide-by-zero
        if isnan(peakVal) || peakVal == 0
            normalizedStruct.(fieldName) = nan(size(signal));
        else
            normalizedStruct.(fieldName) = signal ./ peakVal;
        end
    end

    % Save normalized struct
    normalizedDataTable.(normalizedDataColName)(i) = normalizedStruct;
end

end
