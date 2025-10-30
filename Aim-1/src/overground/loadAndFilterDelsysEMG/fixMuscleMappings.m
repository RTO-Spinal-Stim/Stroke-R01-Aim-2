function [preprocessed_data_fixed] = fixMuscleMappings(preprocessed_data)

%% PURPOSE: REARRANGE THE MUSCLE NAMES FOR SPECIFIC SUBJECTS & INTERVENTIONS
% Inputs
% preprocessed_data: Struct where each field is one muscle's data
%
% Outputs:
% preprocessed_data_fixed: Struct where each field is one muscle's data
%
% NOTE: The order of rearranging muscles is hard coded for spinal stim
% subjects SS08, SS09, SS10

% Initialize the struct with the mixed up data
preprocessed_data_fixed = preprocessed_data;

% Fix the order of the data
preprocessed_data_fixed.RVL = preprocessed_data.RTA;
preprocessed_data_fixed.LHAM = preprocessed_data.RVL;
preprocessed_data_fixed.LRF = preprocessed_data.LHAM;
preprocessed_data_fixed.LMG = preprocessed_data.LRF;
preprocessed_data_fixed.LTA = preprocessed_data.LMG;
preprocessed_data_fixed.LVL = preprocessed_data.LTA;
preprocessed_data_fixed.RTA = preprocessed_data.LVL;

