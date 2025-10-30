function filteredEMG = preprocessEMG(EMGDataStruct, filterEMGConfig, EMG_Fs)

%% PURPOSE: PRE-PROCESS THE EMG DATA AND PLACE IN STRUCT

% Initialize struct to store filtered EMG
filteredEMG = struct();

% Loop through each trial field in the struct
trialFields = fieldnames(EMGDataStruct);
for trialIndex = 1:numel(trialFields)
    trialData = EMGDataStruct.(trialFields{trialIndex});
    filteredTrialEMG = struct();
    
    % Loop through each muscle field in the trial data
    muscleFields = fieldnames(trialData);
    for muscleIndex = 1:numel(muscleFields)
        emg_signal = trialData.(muscleFields{muscleIndex});
        
        [emg_envelope] = filterEMGOneMuscle(emg_signal, filterEMGConfig, EMG_Fs);
        
        % Store filtered EMG in filtered trial EMG struct
        filteredTrialEMG.(muscleFields{muscleIndex}) = emg_envelope;
    end
    
    % Store filtered trial EMG in filteredEMG struct
    filteredEMG.(trialFields{trialIndex}) = filteredTrialEMG;
end
