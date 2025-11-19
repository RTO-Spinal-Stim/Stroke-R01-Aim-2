function [perGaitCycleStruct] = splitDelsysTrialByGaitCycle(structData, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SPLIT A TRIAL OF DELSYS EMG DATA BY GAIT CYCLES.
% Inputs:
%   structData: Struct of data for one trial, each field is one muscle
%   heel_strike_indices: Numeric vector of heel strike indices in the data

muscleNames = fieldnames(structData);
perGaitCycleStruct = struct();
for fieldNum=1:length(muscleNames)
    muscle = muscleNames{fieldNum};
    if muscle(1) == 'L'
        perGaitCycleStruct.(muscle) = splitDataByGaitCycle(structData.(muscle), left_heel_strike_indices);
    elseif muscle(1) == 'R'
        perGaitCycleStruct.(muscle) = splitDataByGaitCycle(structData.(muscle), right_heel_strike_indices);
    else
        error('Muscle name does not start with L or R');
    end
end