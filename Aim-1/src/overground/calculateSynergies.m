function [numSynergies, VAFs, W, H] = calculateSynergies(emgData, muscleNames, VAFthresh)

%% PURPOSE: CALCULATE THE MUSCLE SYNERGIES PRESENT IN EMG DATA
% Inputs:
% emgData: struct of filtered EMG data. Each field is one muscle. Each
%   muscle's data is a 1xN vector, which can be one gait cycle, one whole
%   trial, etc.
% muscleNames: 1xM array of muscle names. These are the only muscles for 
%   which the synergy is calculated. Also defines the order of the W & H
%   matrices.
% VAFthresh: scalar double integer (0-1). The threshold to determine the
% number of synergies
%
% Outputs:
% numSynergies: scalar double. The number of synergies found.
% VAFs: M x 1 vector of doubles. The Variance Accounted For with each
%   increasing number of synergies
% W: M x numSynergies matrix of doubles. The weights of each muscle at the
%   determined number of synergies (0-1)
% H: numSynergies x N matrix of doubles. The timeseries of synergy activations (0-1)

%% Initialize the return values
numSynergies = NaN;
VAFs = [];
W = [];
H = [];

%% WHEN ONLY LOOKING AT L OR R SIDE INDEPENDENTLY, DATA LENGTH SHOULD ALWAYS BE CONSISTENT.
%% If the data is inconsistent in length, get the shortest amount of data to prep for resampling.
min_n_points = inf;
for i = 1:length(muscleNames)
    muscle_name = muscleNames{i};
    if length(emgData.(muscle_name)) < min_n_points
        min_n_points = length(emgData.(muscle_name));
    end
end

% When there is an asymmetrical number of gait cycles in L vs. R, the fields for the side
% with fewer gait cycles will be empty in the last gait cycle. In this
% case, return NaN.
if min_n_points == 0
    return;
end

%% Aggregate the data into a matrix.
aggEMGData = NaN(length(muscleNames), min_n_points);
for i = 1:length(muscleNames)
    muscle_name = muscleNames{i};
    n_points_original = length(emgData.(muscle_name));
    if n_points_original ~= min_n_points
        % Handle inconsistent length timeseries, just in case.
        dataToStore = resample(emgData.(muscle_name), min_n_points, n_points_original);        
    else
        dataToStore = emgData.(muscle_name);
    end
    aggEMGData(i,:) = dataToStore;
end

%% Check for NaN
nanIdx = isnan(aggEMGData);
anyMusclesNaN = any(all(nanIdx,2));
if anyMusclesNaN
    return;
end

%% Turn off the warning about nnmf low rank
warningName = 'stats:nnmf:LowRank';
warningStruct = warning('query', warningName);
warning('off', warningStruct.identifier);

%% Calculate Variance Accounted For (VAF)
% Perform non-negative matrix factorization (nnmf) to extract synergies and weights
maxNumSynergies = size(aggEMGData,1);
VAFs = NaN(maxNumSynergies,1);
for i = 1:maxNumSynergies
    [Wtmp, Htmp] = nnmf(aggEMGData, i);
    reconstruction = Wtmp * Htmp;
    VAFs(i) = 1 - sum((aggEMGData - reconstruction).^2, 'all') / sum(aggEMGData.^2, 'all');
end

%% Reset the warning back to its original state.
warning(warningStruct.state, warningStruct.identifier);

%% Get the number of synergies
numSynergies = find(VAFs >= VAFthresh,1,'first');

%% Get the weights and time series from the W & H matrices with the determined number of synergies
[W, H] = nnmf(aggEMGData, numSynergies);