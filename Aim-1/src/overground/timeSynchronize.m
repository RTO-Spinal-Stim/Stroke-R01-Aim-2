function [tableOut] = timeSynchronize(tableData, fs, secondsColName, framesColName)

%% PURPOSE: SYNCHRONIZE THE GAIT EVENT INDICES, PHASE DURATIONS, ETC. ACROSS HARDWARE TYPES.
% Inputs:
% tableData: The table of data to time synchronize
% fs: The sampling rate
% secondsColName: The column name with the event data in seconds
% framesColName: The column name to store the data in seconds to
%
% Outputs:
% tableOut: The data stored as a table

disp('Time synchronizing data');

tableOut = copyCategorical(tableData);
for i = 1:height(tableData)
    currStruct = getHardwareIndicesFromSeconds(tableData.(secondsColName)(i), fs);
    tableOut.(framesColName)(i) = currStruct;    
end