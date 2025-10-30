function [final_signal, emg_bandpass] = filtering_pipelineFunction(emg_signal,upperLegs, frequency)
    % Step 1 - demean:
    emg_subtracted_mean = bsxfun(@minus, emg_signal, mean(emg_signal));

    % Step 2 - bandpass 10 to 400 Hz. 
    fpass = [10 400]; % Passband frequencies in Hz
    order = 4; % Filter order
    EMG_Fs = 2000;
    [b, a] = butter(order, fpass / (EMG_Fs / 2), 'bandpass');
    emg_bandpass = filtfilt(b, a, emg_subtracted_mean);


    % Step 3 - Perform notch filter after identifying peaks of FFT
    % Will only be perfomed for UPPER legs? and non sham stim?
    if upperLegs == true & frequency~=0 % cannot be sham stim
        if frequency == 50
            minPeakDistance = 45;
        elseif frequency == 30
            minPeakDistance = 25;
        end 

        % Perform FFT
        Y = fft(emg_bandpass);
        
        L = length(emg_bandpass); 
        % Compute the two-sided spectrum and the single-sided spectrum
        P2 = abs(Y/L);            % Two-sided spectrum
        P1 = P2(1:L/2+1);         % Single-sided spectrum
        P1(2:end-1) = 2*P1(2:end-1);

        % Frequency vector
        f = EMG_Fs*(0:(L/2))/L;
        % Identify Peaks in the FFT
        min_prominence = 0.05 * max(P1); 
        [peak_values, peak_indices] = findpeaks(P1, f, ...
                                                'MinPeakProminence', min_prominence, ...
                                                'MinPeakDistance', minPeakDistance); % Adjust distance if needed


         % Filter using notch filter:
         filtered_signal = emg_bandpass;
         for f0 = peak_indices
            Q = 50; % Quality factor (adjust to narrow or widen notch filter)
            [b, a] = iirnotch(f0/(EMG_Fs/2), f0/(EMG_Fs/2)/Q); % Design notch filter
            filtered_signal = filter(b, a, filtered_signal); % Apply filter
         end
         
         
        final_signal = filtered_signal; 
	else
        final_signal= emg_bandpass; 
    end 

end
