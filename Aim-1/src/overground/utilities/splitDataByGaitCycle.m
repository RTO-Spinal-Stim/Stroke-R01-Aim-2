function [tableOut] = ...
    splitDataByGaitCycle(left_data_in, right_data_in, left_heel_strike_indices, right_heel_strike_indices)

%% PURPOSE: SEGMENT A LEFT AND RIGHT SIGNAL INTO LEFT AND RIGHT GAIT CYCLES.
% Inputs:
%   left_data: Numeric vector of data from the left side for one trial
%   right_data: Numeric vector of data from the right side for one trial
%   left_heel_strike_indices: Numeric vector of left heel strike indices in the data
%   right_heel_strike_indices: Numeric vector of right heel strike indices in the data
% Outputs:
%   left_data_by_gait_cycle: Cell array, where each cell is one left gait
%   cycle's data
%   right_data_by_gait_cycle: Cell array, where each cell is one right gait
%   cycle's data
%   start_foot_by_gait_cycle: Cell array, 'L' when the matched gait cycle
%   starts with a L gait cycle, 'R' when the matched gait cycle starts with
%   a R gait cycle.
%
% HOW THIS WORKS:
% 1. The number of matching/paired gait cycles is the number of heel strikes minus 3.
% Minus 3 because each pair of gait cycles has 4 heel strikes, which counts
% as one paired gait cycle.
% 2. The ipsilateral gait cycle is the first and third of each set of four
% heel strikes, while the contralateral gait cycle is the second and
% fourth. For example, if the pair of gait cycles starts with a R heel
% strike, then the R gait cycle is the first and third heel strikes, while
% the L gait cycle is the second and fourth heel strikes. Iterating over
% heel strikes 1:N-3 gives all pairs of gait cycles.

all_heel_strike_indices = sort([left_heel_strike_indices; right_heel_strike_indices]);
numHeelStrikes = length(all_heel_strike_indices);
if numHeelStrikes <= 3
    error('Not enough steps to segment by gait cycle!');
end

numCycles = numHeelStrikes - 3;
tableOut = table;
for cycleNum = 1:numCycles      
    
    tmpTable = table;
    
    firstStepIdx = all_heel_strike_indices(cycleNum);
    secondStepIdx = all_heel_strike_indices(cycleNum+1);
    thirdStepIdx = all_heel_strike_indices(cycleNum+2);
    fourthStepIdx = all_heel_strike_indices(cycleNum+3);

    if ismember(firstStepIdx, left_heel_strike_indices)
        start_foot = 'L';
        left_data = left_data_in(firstStepIdx:thirdStepIdx-1);
        right_data = right_data_in(secondStepIdx:fourthStepIdx-1);
    elseif ismember(firstStepIdx, right_heel_strike_indices)
        start_foot = 'R';
        right_data = right_data_in(firstStepIdx:thirdStepIdx-1);
        left_data = left_data_in(secondStepIdx:fourthStepIdx-1);
    end

    tmpTable.Name = convertCharsToStrings(['cycle' num2str(cycleNum)]);
    tmpTable.L_Data = {left_data};
    tmpTable.R_Data = {right_data};
    tmpTable.StartFoot = convertCharsToStrings(start_foot);

    tableOut = [tableOut; tmpTable];

end