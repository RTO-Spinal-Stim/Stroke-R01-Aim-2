

%% Start processing
final_muscles_list_fieldNames = fieldnames(tepsResultTableOneSubject.(rectifiedMethod)(1));

for mus_i = 1:length(final_muscles_list_fieldNames)

    muscle_channel = final_muscles_list_fieldNames{mus_i};


    % Creating the muscle table that contains ALL inter, tp,
    % and pulses
    singleMuscle_table = table(); % only contains muscle specific pulses - to be added to all_struct
    figureHandle = figure;


    trials_table = subj_Struct.(SUBJ).(INTER).(TP).(plotMethod).(muscle_channel);

    % Iterate through each pulse - trials_table(1,:)
    total_pulses=size(trials_table,1);

    %%% Check that there are 5 pulses per intensity
    % 5 pulses per intensity - every 10 mA
    interval_mA = 10; %mA
    pulses_perIntensity = 5; % 5 trials

    max_intensity = ceil(total_pulses/pulses_perIntensity)*interval_mA;



    % Defining pulse per muscle iteration variables:
    numNan = 0; % Counting the trials that return nan - after 20 mA - just stop and move on
    autofill = false;

    % There should be multiples of 5 in each intensity
    if mod(total_pulses,pulses_perIntensity) ~= 0
        disp([SUBJ + ' ' + muscle_channel + ' ' + INTER + ' ' + TP]);
        disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);


    end

    
    %
    %   ############### decide on peakAuto - include stim onset

    % now iterate through muscles:
    for pulseNum = total_pulses:-1:1
        intensity_value = ceil(pulseNum/pulses_perIntensity)*interval_mA;
        signal = trials_table(pulseNum,:);
        % Latency has to be found from the stim ONSET.

        [minIDX, maxIDX, min_mV, max_mV, p2p, latency, End,  STIM_ARTIFACT_PEAK] =...
            peaksAuto(signal, foundLat, minIDX_picked, maxIDX_picked, sitmIDX_picked);
        % For trials that find peaks before/after latency

        latency_fromOnset_idx = NaN; % Defining the latency - if a lat was found will be corrected below.
        % Keep a counter of how mane have been return with no latency - assumes there is no mep
        if isnan(latency)
            numNan = numNan +1;

            if numNan == 10
                autofill = true;
            end

        elseif ~isnan(latency)
            numNan = 0;
            latency_fromOnset_idx = latency -STIM_ARTIFACT_PEAK;

            % If there is a response - get AUC:
            rect_sig = abs(signal);
            AUC_lat_100 = getAUC(rect_sig, latency, End, 2000);

            % Smooth AUC
            cutoffFreq = 20;  % Low-pass filter cutoff frequency
            [b_sm, a_sm] = butter(4, cutoffFreq/(2000/2), 'low');  % Create filter
            smoothSignal = filtfilt(b_sm, a_sm, rect_sig);  % Apply filter
            AUC_smoothed = getAUC(smoothSignal, latency, End, 2000);
        end


        %% ###############################################


        % Autofill rest of the table
        if autofill == true

            minIDX = NaN;
            maxIDX = NaN;
            min_mV= NaN;
            max_mV = NaN;
            p2p = NaN;
            latency = NaN;
            latency_fromOnset_idx = NaN;
            cell_signal = strjoin(string(signal), ', ');

            maxIDX_picked = NaN;
            minIDX_picked = NaN;



            new_row = table({SUBJ},{INTER}, {TP},{convertCharsToStrings(muscle_channel)},...
                pulseNum, intensity_value, minIDX, maxIDX, min_mV, max_mV, p2p,AUC_lat_100, AUC_smoothed, STIM_ARTIFACT_PEAK, latency, latency_fromOnset_idx,  End,...
                maxIDX_picked,minIDX_picked,...
                'VariableNames', {'SUBJ','INTER','TP','MUSCLE','pulseNum','intensity_value','minIDX','maxIDX','min_mV','max_mV','p2p','AUC_lat_100','AUC_smoothed',...
                'STIM_ARTIFACT_PEAK','latency','latency_fromOnset_idx','End','maxIDX_picked','minIDX_picked'});
            new_row.Data = {cell_signal};
            p2pTable = [p2pTable; new_row];


            singleMuscle_table = [singleMuscle_table; new_row];

        else
            % Create a row to save in excel file:
            %                        new_row = table(SUBJ,INTER, TP,convertCharsToStrings(muscle_channel),...
            %                                         pulseNum, intensity_value, minIDX, maxIDX, min_mV, max_mV, p2p,AUC_lat_100, AUC_smoothed, STIM_ARTIFACT_PEAK, latency, latency_fromOnset_idx,  End,...
            %                                         maxIDX_picked,minIDX_picked, sitmIDX_picked );
            new_row = table({SUBJ},{INTER}, {TP},{convertCharsToStrings(muscle_channel)},...
                pulseNum, intensity_value, minIDX, maxIDX, min_mV, max_mV, p2p,AUC_lat_100, AUC_smoothed, STIM_ARTIFACT_PEAK, latency, latency_fromOnset_idx,  End,...
                maxIDX_picked,minIDX_picked,...
                'VariableNames', {'SUBJ','INTER','TP','MUSCLE','pulseNum','intensity_value','minIDX','maxIDX','min_mV','max_mV','p2p','AUC_lat_100','AUC_smoothed',...
                'STIM_ARTIFACT_PEAK','latency','latency_fromOnset_idx','End','maxIDX_picked','minIDX_picked'});

            % Saving"
            %maxIDX_picked,minIDX_picked - this is what was clicked in
            %the all data
            new_row.Data = strjoin(string(signal), ', ');
            p2pTable = [p2pTable; new_row];

            % Also have muscle only table:
            singleMuscle_table = [singleMuscle_table; new_row];

        end
    end

    % Save in a struct
    % Subj - Inter - TP - MUSCLE - TABLE WITH FEATURES PER PULSE
    ALL_SUBJ_STRUCT.(SUBJ).(INTER).(TP).(muscle_channel)=singleMuscle_table;

    newEntry = table(INITIALS, string(datestr(now, 'ddmmmyyyy')), string(INTER), string(TP), string(muscle_channel),...
        'VariableNames', {'Intials', 'Date', 'Intervention', 'Timepoint', 'Muscle'});

    % Append the new entry to the existing data
    existingData = [existingData; newEntry]; %#ok<AGROW>
    % Write the updated table back to the Excel file
    writetable(existingData, xlsxLogFile, 'WriteMode', 'overwrite');

end