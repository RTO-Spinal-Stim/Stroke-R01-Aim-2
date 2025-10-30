function [struct_stimONSET_INDEX_EMG_trials] = getStimOnsetMax(EMG_raw_struct)

%% PURPOSE: IDENTIFY WHERE THE STIMULATION ARTIFACT IS LOCATED.
% Inputs:
% EMG_raw_struct: Struct where each field is one muscle's MxN EMG data,
% where M = # pulses, N = length of each pulse
%
% Outputs:
% struct_stimONSET_INDEX_EMG_trials: Struct with the index of the
% stimulation artifact in each trial.

MAX_LOOKUP= 55;
musc_fieldnames = fieldnames(EMG_raw_struct);
for channel_num = 1:numel(musc_fieldnames)
    muscle = musc_fieldnames{channel_num};
    muscles_trials = EMG_raw_struct.(muscle);

    trials_total = size(muscles_trials,1);
    for pulsenum = trials_total:-1:1
        emg_sig = muscles_trials(pulsenum,:);

        % Normally peak will be betweeen 0 to MAX_LOOKUP idx
        if pulsenum == trials_total
            % Find the reference stim peak


            approx_signal_artifact = diff(emg_sig(1:MAX_LOOKUP));


            [pks, locs] = findpeaks(approx_signal_artifact);
            [maxPeak, idx] = max(pks);
            stim_onset_max_REFERENCE = locs(idx);

            % OLD WAY:
            %extrema_indices_STIM = find(diff(sign(diff(approx_signal_artifact))) == -2) ;

            %[~, max_peak_index_OF_extrema_indices_STIM] = max(approx_signal_artifact(extrema_indices_STIM)); % tells you what index is the max
            % Correct so indices are in the indices of original long singal
            % INDEX IN SIGNAL WHERE HAVE STIM:
            %stim_onset_max_REFERENCE = extrema_indices_STIM(max_peak_index_OF_extrema_indices_STIM);

            struct_stimONSET_INDEX_EMG_trials.(muscle)(pulsenum,:) = stim_onset_max_REFERENCE;
        else
            % Now find the max within +-25 of that reference
            within_lookup = 25;

            if stim_onset_max_REFERENCE <= 25
                within_lookup = stim_onset_max_REFERENCE-1;
            end

            % End look up should be MAX_LOOKUP
            end_lookup = stim_onset_max_REFERENCE+25;
            if stim_onset_max_REFERENCE+25 > MAX_LOOKUP
                end_lookup = MAX_LOOKUP;
            end


            approx_signal_artifact = diff(emg_sig(stim_onset_max_REFERENCE - within_lookup: end_lookup));




            [pks, locs] = findpeaks(approx_signal_artifact);
            [maxPeak, idx] = max(pks);
            stim_onset_max = locs(idx)+ stim_onset_max_REFERENCE - within_lookup;




            %
            %                 extrema_indices_STIM = find(diff(sign(diff(approx_signal_artifact))) == -2) ;
            %
            %                 [~, max_peak_index_OF_extrema_indices_STIM] = max(approx_signal_artifact(extrema_indices_STIM)); % tells you what index is the max
            %                 % Correct so indices are in the indices of original long singal
            %                 extrema_indices_STIM = extrema_indices_STIM + stim_onset_max_REFERENCE - within_lookup;
            %
            %
            %                 stim_onset_max = extrema_indices_STIM(max_peak_index_OF_extrema_indices_STIM);
            %
            if isempty(stim_onset_max)
                struct_stimONSET_INDEX_EMG_trials.(muscle)(pulsenum,:) = NaN;
            else
                struct_stimONSET_INDEX_EMG_trials.(muscle)(pulsenum,:) = stim_onset_max;
            end
        end

    end
end
end

%%
% %Double check by plotting:
% MUS= "LTA"
% figure
% pulse = 90;
% emg_sig= subj_Struct.SS03.RMT30.POST.BandPass.(MUS)(pulse,:);
% plot(emg_sig)
%
% hold on
% xline(subj_Struct.SS03.RMT30.POST.StimOnsetPeaks.(MUS)(pulse,:))
% %
% MAX_LOOKUP = 55;
% approx_signal_artifact = diff(emg_sig(1:MAX_LOOKUP));
%
%
% stim_onset_max_REFERENCE = 49;
%
%
% approx_signal_artifact = diff(emg_sig(stim_onset_max_REFERENCE - 25: 55));
%
%
%
%
% [pks, locs] = findpeaks(approx_signal_artifact);
% [maxPeak, idx] = max(pks);
% stim_onset_max = locs(idx)+ stim_onset_max_REFERENCE - 25;