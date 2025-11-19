% plot_status = false; % Whether or not to plot.
SUBJ = "SS13"; % Subject Name
% Paths
if ispc==1
    % For adding code paths.
    paths_to_add = {...
        'Y:\LabMembers\MTillman\Code\From_Nicole\Stim ON pipeline\functions'...
        };
    subject_data_load_path = 'Y:\Spinal Stim_Stroke R01\AIM 1\Record while stim ON';
    subject_data_save_path = 'Y:\LabMembers\MTillman\Code\From_Nicole\Stim ON pipeline';
else
    paths_to_add = {};
end
for i=1:length(paths_to_add)
    addpath(genpath(paths_to_add{i}));
end

% Paths
% For loading subject data. Was previously "subject_path_MASTER"

subject_load_path = fullfile(subject_data_load_path, SUBJ);
% For saving subject data.
subject_save_path = fullfile(subject_data_save_path, SUBJ);
if ~exist(subject_save_path,'dir')
    mkdir(subject_save_path);
end

% Pre-processing for IMU and EMG data.
A_PreProcess_xsens_emg;

% Segment each gait cycle in the treadmill walking data.
B_GetGaitCycles;

% Prep for non-negative matrix factorization (NMF)
C_Prep_for_NMF;

% Exploration of muscle synergies
D_MuscleSynergy_Explore;