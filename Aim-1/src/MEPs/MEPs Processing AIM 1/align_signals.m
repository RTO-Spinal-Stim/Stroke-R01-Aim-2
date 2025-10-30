function [struct_EMG_trials_shift, struct_EMG_trials_shiftIDX] = align_signals(EMG_Struct)

%% PURPOSE: SHIFT THE SIGNALS IN TIME...
% Inputs: 
% EMG_Struct: Struct where each field is one muscle's MxN EMG data, where M
% = # pulses, N = length of each pulse.
%
% Outputs:
% struct_EMG_trials_shift: Struct where each field is the shifted EMG data.
% struct_EMG_trials_shiftIDX: Struct of indices shifted by.

struct_EMG_trials_shift = struct();
musc_fieldnames = fieldnames(EMG_Struct);
for channel_num = 1:numel(musc_fieldnames)
    muscle = musc_fieldnames{channel_num};
    muscles_trials = EMG_Struct.(muscle);
    last_sig_i = size(muscles_trials,1);
    ref_sig = muscles_trials(last_sig_i,:);

    for pulsenum = 1:last_sig_i-1
        % iterate through all the pulses, and shift respective to reference
        sig_toShift = muscles_trials(pulsenum,:);
        % Compute cross-correlation
        [crossCorr, lags] = xcorr(sig_toShift, ref_sig);


        % Find the index of the maximum correlation
        [~, maxIndex] = maxk(crossCorr,3);

        % Compute the lag between the signals
        lagDiff = lags(maxIndex);

        for i=1:3

            if abs(lagDiff(i)) < 20 % if the shift is too much, move on to next one
                % Align the signals by shifting one by the lag difference
                %alignedSignal = circshift(sig_toShift, -lagDiff);

                alignedSignal = zeros(size(sig_toShift));




                % Shift left and fill the rest with zeros
                %A negative lag means the sig_toShift needs to be shifted forward (delayed) to align with ref_sig,
                %and a postive lag means sig_toShift should be shifted backward (advanced).
                if lagDiff(i)< 0
                    s = abs(lagDiff(i));
                    alignedSignal(s+1:end) = sig_toShift(1:end-s);
                    % shifts to right or forward
                else
                    alignedSignal(1:end-lagDiff(i)) = sig_toShift(lagDiff(i)+1:end);
                    % shifts to left - moving back the amount of
                    % lagDiff
                end

                % Save max lag - this is the amount that has to be ADDDED to any other index to get back OG signal
                shiftedAmount = -1*lagDiff(i);
                break
            else
                % keep original signal
                alignedSignal = sig_toShift;

                shiftedAmount = 0;
            end
        end



        struct_EMG_trials_shiftIDX.(muscle)(pulsenum,1) = shiftedAmount;
        % This represent the amount that signal was shifted by
        % For example: 2, means signal was shifted by 2 forward
        % -4, signal was shifted -4 points back

        % Index of max correlation (of aligned signals) - did not shift
        % the REF signal - so could see this in respect to this signal
        multi_signals = alignedSignal.*ref_sig;
        [~, maxIndex_alignedSigs] = maxk(multi_signals,1);
        struct_EMG_trials_shiftIDX.(muscle)(pulsenum,2) =  maxIndex_alignedSigs;

        struct_EMG_trials_shift.(muscle)(pulsenum,:) = alignedSignal;
        % Also return the index of max correlation
    end
    struct_EMG_trials_shift.(muscle)(last_sig_i,:) = alignedSignal;

end