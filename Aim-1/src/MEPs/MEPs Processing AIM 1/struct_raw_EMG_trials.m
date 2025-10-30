function [struct_raw_EMG_trials] = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in)

%% PURPOSE: SHAPE THE RAW EMG DATA INTO A STRUCTURE.
% Inputs:
% channels: The names of the muscles, in the order they are included in the file.
% data: 1xN vector of all data
% datastart: The indices where each muscle's data begins
% dataend: The indices where each muscle's data ends
% delete_in: The pulse numbers to remove
%
% Outputs:
% struct_raw_EMG_trials: Struct where each field is the raw data for one
% muscle.

struct_raw_EMG_trials = struct();

for channel_num = 1:length(channels)
    channel = channels{channel_num};
    for pulsenum = 1:size(datastart,2) 
        frame_start = datastart(channel_num,pulsenum);
        frame_end = dataend(channel_num,pulsenum); % collects for 100ms at 2000 Hz samprate
        struct_raw_EMG_trials.(channel)(pulsenum,:) = data(frame_start:frame_end);
    end

    % Remove bad pulses: removes rows specified here
    if ~isnan(delete_in) % if is not nan - then remove rows
        struct_raw_EMG_trials.(channel)(delete_in,:) = [];
    end
end