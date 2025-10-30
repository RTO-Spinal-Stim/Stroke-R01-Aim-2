function struct_raw_EMG_trials = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in)
% f and e are the filter defined outside function
    struct_raw_EMG_trials = struct();
    
    for channel_num = 1:numel(channels)
        for pulsenum = 1:size(datastart,2) 

            frame_start = datastart(channel_num,pulsenum);
            frame_end = dataend(channel_num,pulsenum); % collects for 100ms at 2000 Hz samprate
            struct_raw_EMG_trials.(channels{channel_num})(pulsenum,:) = data(frame_start:frame_end);

        end
    
    
        % Remove bad pulses:
        % removes rows specified here
        if ~isnan(delete_in) % if is not nan - then remove rows
            struct_raw_EMG_trials.(channels{channel_num})(delete_in,:) = [];
        end
    end

end
