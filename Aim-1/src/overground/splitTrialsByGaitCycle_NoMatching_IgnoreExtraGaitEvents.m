function [tableOut] = splitTrialsByGaitCycle_NoMatching_IgnoreExtraGaitEvents(tableIn, colNamesToSplit, gaitEventsColNames)

%% PURPOSE: SPLIT THE TRIALS BY GAIT CYCLE, IGNORE GAIT EVENTS THAT OCCUR AFTER THE TRIAL ENDS.
% Inputs:
% tableIn: The input data table
% colNamesToSplit: Cell array of the column names for the data to split
% gaitEventsColNames: Cell array of the column names for the gait events, in the same
% order as the `colNamesToSplit`
% sampleRates: The sampling rates of the hardware systems
%
% tableOut: The table of data split by gait cycles

disp('Segmenting data by gait cycle, ignoring extra gait events');

% Validate inputs
assert(iscell(colNamesToSplit));
assert(iscell(gaitEventsColNames));
assert(length(colNamesToSplit) == length(gaitEventsColNames));

for i = 1:height(tableIn)

    % Get the last toe off index that is common to all timeseries (less than the length of the shortest timeseries)
    lastGaitEventCount = NaN(length(colNamesToSplit),1);
    lastGaitEventSampleNum = NaN(size(lastGaitEventCount));
    for colNum = 1:length(colNamesToSplit)
        colNameToSplit = colNamesToSplit{colNum};
        gaitEventsColName = gaitEventsColNames{colNum};
        LTO = tableIn.(gaitEventsColName)(i).gaitEvents.leftToeOffs;
        RTO = tableIn.(gaitEventsColName)(i).gaitEvents.rightToeOffs;
        LHS = tableIn.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
        RHS = tableIn.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes;
        allGaitEvents = sort([LTO; RTO; LHS; RHS]);
        currDataStruct = tableIn.(colNameToSplit)(i); % A struct
        fldNames = fieldnames(currDataStruct);
        currTimeseries = currDataStruct.(fldNames{1});
        lastGaitEventCount(colNum) = find(allGaitEvents < length(currTimeseries),1,'last');
        lastGaitEventSampleNum(colNum) = allGaitEvents(lastGaitEventCount(colNum));
    end
    minLastGaitEventCount = min(lastGaitEventCount); % Identify the last toe off that is common to all timeseries    

    % Remove the gait events after that last toe off.
    for colNum = 1:length(gaitEventsColNames)
        gaitEventsColName = gaitEventsColNames{colNum};
        % Extract the data
        LHS = tableIn.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes;
        RHS = tableIn.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes;
        LTO = tableIn.(gaitEventsColName)(i).gaitEvents.leftToeOffs;
        RTO = tableIn.(gaitEventsColName)(i).gaitEvents.rightToeOffs;
        allGaitEvents = sort([LHS; RHS; LTO; RTO]);
        lastGaitEventSampleNum = allGaitEvents(minLastGaitEventCount);
        % Filter to only include the designated gait events
        LHS = LHS(LHS <= lastGaitEventSampleNum);
        RHS = RHS(RHS <= lastGaitEventSampleNum);
        LTO = LTO(LTO <= lastGaitEventSampleNum);
        RTO = RTO(RTO <= lastGaitEventSampleNum);
        % Put the data back in to the table
        tableIn.(gaitEventsColName)(i).gaitEvents.leftHeelStrikes = LHS;
        tableIn.(gaitEventsColName)(i).gaitEvents.rightHeelStrikes = RHS;
        tableIn.(gaitEventsColName)(i).gaitEvents.leftToeOffs = LTO;
        tableIn.(gaitEventsColName)(i).gaitEvents.rightToeOffs = RTO;
    end

end

%% Perform the actual splitting of trials by gait cycle
tableOut = table;
for colNum = 1:length(colNamesToSplit)
    colNameToSplit = colNamesToSplit{colNum};
    gaitEventsColName = gaitEventsColNames{colNum};
    tmpTable = splitTrialsByGaitCycle_NoMatching(tableIn, colNameToSplit, gaitEventsColName);
    tableOut = addToTable(tableOut, tmpTable);
end