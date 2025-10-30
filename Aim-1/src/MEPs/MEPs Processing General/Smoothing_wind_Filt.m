function struct_filt_EMG_trials = Smoothing_wind_Filt(EMG_raw_struct, windowDuration, samprate)
% f and e are the filter defined outside function
    windowSize = round(samprate * windowDuration); % Window size in samples
    window = ones(1, windowSize) / windowSize;

    musc_fieldnames = fieldnames(EMG_raw_struct);
    for channel_num = 1:numel(musc_fieldnames)
        muscle = musc_fieldnames{channel_num};
        muscles_trials = EMG_raw_struct.(muscle); 
        for pulsenum = 1:size(muscles_trials,1)

            emg_sig = muscles_trials(pulsenum,:);
            % Low-pass filter
            smoothedSignal = conv(emg_sig, window, 'same'); % Directly filter the signal
            struct_filt_EMG_trials.(muscle)(pulsenum,:) = smoothedSignal;
        end
    end
 
end
