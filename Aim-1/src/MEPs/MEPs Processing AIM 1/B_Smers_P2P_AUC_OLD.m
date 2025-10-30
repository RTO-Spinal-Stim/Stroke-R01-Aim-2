INITIALS = "MT";

% SUBJ_list = ["01"]%, "01","02", "03", "04", "05", "06"];%, "08", "09", "10"];
% TP_list = ["PRE","POST"]; 
% 
% INTER_list = ["RMT50"]%,RMT30 "TOL30", "RMT50", "TOL50", "SHAM1", "SHAM2"]; 

colors = { [0 0 1 0.1],[0.9290 0.6940 0.1250], [1 0 0 0.5]};
                % blue, yellow, red - blue comes first 
                
subj_path_suffix = '\TEPs\TEPsProcessed';
                
plotMethod = "BandPass";
rectifiedMethod = "Rectified_afterAligSmooth";

%% Read in master TEPs file
% Obtains the bad pulses for each MEP trial. 

% aim1_folder = "Y:\Spinal Stim_Stroke R01\AIM 1"; 
% subj_path = fullfile(aim1_folder, 'Subject Data');

p2p_table = table();  % gets ALLL IN ONE TABLE
% NEED TO DO CODE THAT READS IN THE SAVED STRUCT AND ONLY DOES THE ONES
% THAT ARE NOT DONE YET.
% START ITERATING AND IF THAT FIELDNAME PATH EXISTS, CONTINUE - BUT READ IN
% STRUCT FIRST. - AND THEN APPEND THE NEW P2P table created to the one
% existing. OR just have a code later to append all those tables. 

%% START ITERATION
for SUBJ_i = 1:length(SUBJ_list)
    missingFiles = {};
    SUBJ = SUBJ_list{SUBJ_i};
    curr_subj_path = strcat(subj_path_prefix, SUBJ, subj_path_suffix);
    curr_subj_save_path = strcat(subj_save_path_prefix, SUBJ, subj_path_suffix);
    
    % CREATE THE PROCESSED LOG:
    % Initialize Excel file and header (if it doesn't exist)
    outputFile = fullfile(curr_subj_path, 'ProcessedCombinations.xlsx');
    
        % Check if the file exists
    if isfile(outputFile)
        % Read the existing data from the Excel file
        existingData = readtable(outputFile);
    else
        % If the file doesn't exist, create an empty table with appropriate headers
        existingData  = table("ProcessorIntital" , "Date", "INTERVENTION", "TIMEPOINT", "MUSCLE",...
                             'VariableNames', {'Intials', 'Date', 'Intervention', 'Timepoint', 'Muscle'});
    end

  

    % find the latest one
    a_smers_files = {dir(fullfile(curr_subj_path, '*.mat')).name}; 
    % filter to those that contain "_pre_processedTEPs_"
    a_smers_files = a_smers_files(contains(a_smers_files, "A_" +SUBJ  +"_pre_processedTEPs_"));
    if length(a_smers_files)>1
        datenums = cellfun(@(x) x.datenum, a_smers_files);
        [~, latestIndex] = max(datenums);
        filename_preprocessed= a_smers_files{latestIndex};
        
    elseif length(a_smers_files)==1
        filename_preprocessed = a_smers_files{1};
    else
        disp(SUBJ + " Does not have a file - go process it in code A")
        continue;
    end
    
    final_path = fullfile(curr_subj_path, filename_preprocessed);
    % Load the struct:
    load(final_path) % subj_Struct
    
    
    
    for INTER_i = 1: length(INTER_list)
        INTER_number_first = INTER_list{INTER_i};
        INTER = inter_valid_names(INTER_number_first);
        
        % CHECK IF SS0x_B_TEPs_PulsesFeatsStruct.mat exist, 
        
        % if it does - load 
        mat_struct_path = fullfile(curr_subj_path, "B_" +SUBJ+"_" + INTER_number_first  +"_TEPs_PulsesFeatsStruct.mat");
        if exist(mat_struct_path, 'file') == 2
            % the file for that intervention was already processed:
            disp( "B_" +SUBJ+"_" + INTER  +"_TEPs_PulsesFeatsStruct.mat" + " was already processed. Skipping.");
            
            % Check if pre or post is missing:
            TP_LIST_DONE = fieldnames(ALL_SUBJ_STRUCT.(SUBJ).(INTER));
            TP_list=setdiff(TP_list, fieldnames(ALL_SUBJ_STRUCT.(SUBJ).(INTER))); % if length is 0, then the foor loop below will not run
            % this is done is only PRE was processed - could process post
            % later without having to re-process pre
            
            % COULD CHECK HERE HOW MANY MUSCLES DONE TO SEE SHOULD DO AGAIN
            

        else
            ALL_SUBJ_STRUCT = struct();
            TP_list = ["PRE","POST"];
        end
        
        for TP_i = 1: length(TP_list)
            TP = TP_list(TP_i);
            
        
            final_muscles_list_fieldNames = fieldnames(subj_Struct.(SUBJ).(INTER).(TP).(plotMethod));
            
            for mus_i =1: length(final_muscles_list_fieldNames)
                
                
                muscle_channel = final_muscles_list_fieldNames{mus_i}; 
                
                
                if isfield(ALL_SUBJ_STRUCT, SUBJ) && ...
                   isfield(ALL_SUBJ_STRUCT.(SUBJ), INTER) && ...
                   isfield(ALL_SUBJ_STRUCT.(SUBJ).(INTER), TP) && ...
                   isfield(ALL_SUBJ_STRUCT.(SUBJ).(INTER).(TP), muscle_channel)
                   
                   % If there is a table (or info saved)
                   if istable(ALL_SUBJ_STRUCT.(SUBJ).(INTER).(TP).(muscle_channel))
                       % of there is info saved, moved on to next muscle:
                       continue; 
                   end
               
               
                end
                
                % Check if this particular path has been processed:
                
                
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
                
                for pulseNum = 1:total_pulses
                    signal = trials_table(pulseNum,:);
                    
                    % Get the color for the current iteration
                     percentage = pulseNum / total_pulses * 100;
                     if percentage <= 33
                        colorIndex = 1;

                     elseif percentage <= 66
                        colorIndex = 2; 

                     else
                        colorIndex = 3;
                     end

                     currentColor = colors{colorIndex};

                     % Plot signal
                    plot(signal, 'Color', currentColor)
                    hold on  
                end
                
                

                % Get figure position to calculate button placement
                figPos = get(figureHandle, 'Position');
                buttonWidth = 100;
                buttonHeight = 30;
                buttonLeft = 20;  % Distance from the left edge of the figure
                buttonBottom = (figPos(4) - buttonHeight) / 2;  % Centered vertically

                set(gcf, 'Position', get(0, 'Screensize'));
                title([TP +' ' + muscle_channel  ' - Zoom in as neccesary, decide if proceed or no MEP found'])
                hold on;
                % Create "Continue" and "Skip" buttons with the same callback function
                continueButton = uicontrol('Style', 'pushbutton', 'String', 'Continue',...
                    'Position', [buttonLeft, buttonBottom + 40, buttonWidth, buttonHeight],...
                    'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscle_channel));
                % Alternative for continue - press enter:
                % Set the KeyPressFcn for the figure
                figureHandle.WindowKeyPressFcn = @(src, event) keyPressCallback(src, event, muscle_channel);

                skipButton = uicontrol('Style', 'pushbutton', 'String', 'Skip',...
                    'Position',  [buttonLeft, buttonBottom - 40, buttonWidth, buttonHeight],...
                    'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscle_channel));

                % Pause execution and wait for user action
                uiwait(gcf);
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
                       
                       %subj_Struct.(SUBJ).(INTER).(TP).(rectifiedMethod).(muscle_channel)(pulseNum,:); 
                       
                       AUC_lat_100 = getAUC(rect_sig, latency, End, 2000);
                       
                       
                       %AUC_lat_pickedEnd = getAUC(rect_sig, latency, endIDX_picked, 2000);
                       
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
                        p2p_table = [p2p_table; new_row];
                        
                        
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
                        p2p_table = [p2p_table; new_row];
                        
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
                writetable(existingData, outputFile, 'WriteMode', 'overwrite');
                
            end
            disp(INTER + " " + TP + " DONE")
        end
        
    end
    
    ALL_SUBJ_STRUCT.(SUBJ).("plotMethod")=plotMethod;
    SAVEPATH = fullfile(curr_subj_save_path, "B_" +SUBJ+"_" + INTER  +"_TEPs_PulsesFeatsStruct.mat");
    save(SAVEPATH, "ALL_SUBJ_STRUCT")
end





%% 
% Define the callback function for key press
function keyPressCallback(~, event, muscle_channel)
    % Mimic a button press based on the key
    if strcmp(event.Key, 'return') % 'Enter' key
        % Create a fake src structure for "Continue"
        fakeSrc.String = 'Continue';
        pick_Peaks_inPlot_callback(fakeSrc, muscle_channel);
    elseif strcmp(event.Key, 'backspace') % Optional: Handle other keys like 'Escape'
        % Create a fake src structure for "Skip"
        fakeSrc.String = 'Skip';
        pick_Peaks_inPlot_callback(fakeSrc, muscle_channel);
    end
end
