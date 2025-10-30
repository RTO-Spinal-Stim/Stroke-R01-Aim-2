function struct_filt_EMG_trials = EMG_filt(EMG_raw_struct, f,e)
% f and e are the filter defined outside function

    musc_fieldnames = fieldnames(EMG_raw_struct);
    for channel_num = 1:numel(musc_fieldnames)
        muscle = musc_fieldnames{channel_num};
        muscles_trials = EMG_raw_struct.(muscle); 
        for pulsenum = 1:size(muscles_trials,1)

            emg_sig = muscles_trials(pulsenum,:);
            % Low-pass filter
            EMG_filt = filtfilt(f,e, emg_sig); 
            struct_filt_EMG_trials.(muscle)(pulsenum,:) = EMG_filt;
        end
    end
 
end