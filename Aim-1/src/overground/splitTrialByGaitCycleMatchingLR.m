function [perGaitCycleStruct, maxNumCycles, startFoot] = splitTrialByGaitCycleMatchingLR(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF TIMESERIES DATA BY GAIT CYCLES. MATCHES L & R SIDE DATA FROM L & R GAIT CYCLES TOGETHER INTO ONE GAIT CYCLE.
% Inputs:
% structData: Struct of data for one trial, each field is one signal
% left_heel_strike_indices: Numeric vector of left heel strike indices in the data
% right_heel_strike_indices: Numeric vector of right heel strike indices in the data
% 
% Outputs:
% perGaitCycleStruct: The struct of data split by gait cycle
% maxNumCycles: Scalar double of the maximum number of gait cycles found
%
% NOTE: The data that is split into gait cycles is already staggered by L &
% R gait cycles. Therefore, gait cycle 1's L data is between the first two
% L heel strikes, and gait cycle 1's R data is between the first two R heel
% strikes.

fieldNames = fieldnames(structData);
fieldNamesNoSide = cell(length(fieldNames)/2,1);
for i = 1:length(fieldNamesNoSide)
    fieldNamesNoSide{i} = fieldNames{i}(2:end);
end
fieldNamesNoSide = unique(fieldNamesNoSide);
perGaitCycleStruct = struct();
maxNumCycles = 0;
startFoot = [];
for fieldNum=1:length(fieldNamesNoSide)
    fieldName = fieldNamesNoSide{fieldNum}; 
    fieldNameL = ['L' fieldName];
    fieldNameR = ['R' fieldName];
    
    dataOut = splitDataByGaitCycle(structData.(fieldNameL), structData.(fieldNameR), left_heel_strike_indices, right_heel_strike_indices);
    if isempty(startFoot)
        startFoot = dataOut.StartFoot;
    end

    perGaitCycleStruct.(fieldNameL) = dataOut.L_Data;
    perGaitCycleStruct.(fieldNameR) = dataOut.R_Data;

    maxNumCycles = max([maxNumCycles, height(dataOut)]);
end
