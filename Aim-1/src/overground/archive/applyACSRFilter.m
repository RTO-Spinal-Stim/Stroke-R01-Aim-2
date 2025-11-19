function filteredData = applyACSRFilter(allEMGData, Fs)
    % Parameters for ACSR filter
    window = 0.2 * Fs; % 200 ms

    % Initialize struct to store filtered data
    filteredData = struct();

    % Loop through each trial field in the struct
    trialFields = fieldnames(allEMGData);
    for trialIndex = 1:numel(trialFields)
        trialData = allEMGData.(trialFields{trialIndex});

        % Initialize struct to store filtered trial data
        filteredTrialData = struct();

        % Loop through each muscle field in the trial data
        muscleFields = fieldnames(trialData);
        for muscleIndex = 1:numel(muscleFields)
            emg_signal = trialData.(muscleFields{muscleIndex});

            % Apply ACSR filter to EMG signal
            emg_for_training = emg_signal(1:2*Fs); % Assuming all muscles have the same length
            emg_filtered = ACSR_filter(emg_for_training,emg_signal, window);

            % Store filtered signal in filtered trial data struct
            filteredTrialData.(muscleFields{muscleIndex}) = emg_filtered;
        end

        % Store filtered trial data in filteredData struct
        filteredData.(trialFields{trialIndex}) = filteredTrialData;
    end
end
