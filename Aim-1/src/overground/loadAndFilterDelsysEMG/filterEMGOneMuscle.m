function [filtered_emg] = filterEMGOneMuscle(raw_emg_one_muscle, filterEMGConfig, EMG_Fs, rectify, MVC)

%% PURPOSE: PARSE CONFIGURATION AND FILTER THE RAW EMG DATA
% Inputs:
% raw_emg_one_muscle: Vector of doubles for one muscle's EMG data
% filterEMGConfig: Config struct for the EMG filter
% EMG_Fs: Sampling rate for the EMG
% rectify: 0 or 1 indicating whether or not to rectify the EMG data
% MVC: true or false, indicating if trial is MVC or not
%
% Outputs:
% filtered_emg: The filtered EMG data
%
% example config JSON format:
% {
%   "EMG_SAMPLING_FREQUENCY": 2000,
%   "FILTER_EMG": {
%       "BANDPASS_ORDER": 4,
%       "BANDPASS_CUTOFF": [
%           4, 
%           100
%       ],
%       "LOWPASS_ORDER": 2,
%       "LOWPASS_CUTOFF": 5,
%       "SAMPLING_FREQUENCY": 2000
%   }
% }

% Provide default value
if ~exist('rectify','var')
    rectify = true;
end

rectify = logical(rectify);

% Provide default value for MVC
if ~exist('MVC','var')
    MVC = false;
end
MVC = logical(MVC);

% If the input data is NaN, return NaN
if all(isnan(raw_emg_one_muscle))
    filtered_emg = NaN(size(raw_emg_one_muscle));
    return;
end

% Parameters for bandpass filter
fpass = filterEMGConfig.BANDPASS_CUTOFF;
order = filterEMGConfig.BANDPASS_ORDER;

% Parameters for low-pass filter (envelope)
fcut = filterEMGConfig.LOWPASS_CUTOFF;

% Filter coefficients computed once
[b_band, a_band] = butter(order, fpass / (EMG_Fs / 2), 'bandpass');
[b_low, a_low] = butter(2, fcut / (EMG_Fs / 2), 'low');

% Subtract mean
emg_subtracted_mean = raw_emg_one_muscle - mean(raw_emg_one_muscle);

% Bandpass filter
emg_bandpass = filtfilt(b_band, a_band, emg_subtracted_mean);

% Rectification
if rectify
    emg_rectified = abs(emg_bandpass);

    % Low-pass filter (envelope)
    filtered_emg = filtfilt(b_low, a_low, emg_rectified);
else
    filtered_emg = emg_bandpass; % Assign value to output if not rectifying
end

%% Sliding RMS (100 ms for non-MVC, 300 ms for MVC, no overlap)
if MVC
    win_ms = 300; % MVC trials
else
    win_ms = 100; % non-MVC trials
end

win_samples = round((win_ms/1000) * EMG_Fs); % Convert to samples

n = length(filtered_emg);
rms_emg = zeros(size(filtered_emg));

for i = 1:(n - win_samples + 1)
    idx = i:(i + win_samples - 1);
    rms_val = sqrt(mean(filtered_emg(idx).^2));
    rms_emg(i) = rms_val; % assign RMS value at window start
end

filtered_emg = rms_emg; % Overwrite with RMS-smoothed version

end
