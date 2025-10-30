%
%%
clc
clear
close all
%% User input:

% 1 Open a dialog to select a .mat file
[filename, filepath] = uigetfile('*.mat', 'Select a MAT file');

% Check if the user clicked "Cancel"
if isequal(filename, 0)
    disp('User selected Cancel');
    file_mat_path = '';
else
    % Combine the file name and path
    file_mat_path = fullfile(filepath, filename);
    disp(['User selected: ', file_mat_path]);
end

[general_path, filename_processed, ~] = fileparts(file_mat_path);

% 2. Ask the user to input the number of trials
prompt = {'Enter the number of trials per intensity (usually 5 pulses per intensity):'};
dlgtitle = 'Number of Trials';
dims = [1 35];
defaultInput = {'5'};  % Set default to 1 trial
answer = inputdlg(prompt, dlgtitle, dims, defaultInput);

% Convert answer to a number and store in variable numTrials
if ~isempty(answer)
    pulses_perIntensity = str2double(answer{1});
else
    error('Input canceled or invalid. Please enter a valid number of trials.');
end

% 3. Ask the user for list of bad pulses
choice = questdlg('Do you have any bad pulses to input?', ...
    'Bad Pulses', ...
    'Yes', 'No', 'No');

switch choice
    case 'Yes'
        % Prompt for the list of bad pulses if they selected "Yes"
        prompt = {'Enter list of bad pulses (comma-separated):'};
        dlgtitle = 'Bad Pulses';
        dims = [1 50];
        answer = inputdlg(prompt, dlgtitle, dims);
        
        if ~isempty(answer)
            % Convert the input to a list of numbers
            pulsestodelete = str2num(answer{1}); %#ok<ST2NM> 
            if isempty(pulsestodelete)
                pulsestodelete = []; % Make sure badPulses is an empty list if input was invalid
                warning('Invalid input format. badPulses set to an empty list.');
            end
        else
            pulsestodelete = [];
        end
    case 'No'
        % Set badPulses to an empty list if there are no bad pulses
        pulsestodelete = [];
end

% Display the results
disp(['Number of Trials: ', num2str(pulses_perIntensity)]);
disp(['Bad Pulses: ', mat2str(pulsestodelete)]);



clearvars -except pulsestodelete pulses_perIntensity file_mat_path general_path filename_processed
interval_mA = 10; %mA

% MAKE THE FOLDER TO SAVE ALL THIS:
% Create the full path for the new folder
new_folder_SAVEPATH = fullfile(general_path, filename_processed + "_PROCESSED");

% Create the folder
mkdir(new_folder_SAVEPATH);

% Create a figures folder
new_folder_SAVEPATH_FIGRUES = fullfile(new_folder_SAVEPATH, 'Figures');
mkdir(new_folder_SAVEPATH_FIGRUES);

% For matlab figures:
new_folder_SAVEPATH_FIGRUES_MATLAB = fullfile(new_folder_SAVEPATH_FIGRUES, 'Matlab');
mkdir(new_folder_SAVEPATH_FIGRUES_MATLAB);
%% Processing parameters
lower_extremity = false;
if lower_extremity == true
    final_muscles_list = ["RRF", "LRF", "RHAM", "LHAM", "RVL", "LVL", "RTA", "LTA", "RMG", "LMG"]; 
    number_of_muscles = size(final_muscles_list,2);
end
%% ###############################################
% Opening file

load(file_mat_path);


%% ###############################################
% Establish channels, erase unneed it ones for raw mat file


% Find rows that contain RVL, LRV, STIM, and KNEE to delete
emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows')) find(ismember(titles,'Stim Trig','rows'))];

% Final set of titles
titles(emptyrow_title_in,:) = [];
% Final rows of data
datastart(emptyrow_title_in,:) = [];
number_of_muscles = length(titles);
% Get the order of channels presented in the mat file 
for channel_num = 1:number_of_muscles
    channels{channel_num,1} = strtrim(titles(channel_num,:)); % gives order of channels in the data
end 




%% Creating the structs of filtered data


% ###############
EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, pulsestodelete);
subj_Struct.Raw = EMG_raw_struct;

% CHECK PULSES (RANDOM MUSCLE)
total_pulses=size(EMG_raw_struct.(channels{1}),1);
wrongPulses = NaN;
if mod(total_pulses,pulses_perIntensity) ~= 0
    disp(strcat(subj , " ", session_code  , " ",timepoint));
    disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
    % ADD TO ERROR LIST:
    disp(pulsestodelete);
    wrongPulses{end + 1} = strcat(subj , " ", session_code  , " ",timepoint, " tot pulses " , num2str(total_pulses));
end

% ############### BANDPASS
%A. Bandpass filter design (20-500 Hz)
low_cutoff = 20;  % Lower cutoff frequency (Hz)
high_cutoff = 500; % Upper cutoff frequency (Hz)
samprate = 2000;
[b, a] = butter(4, [low_cutoff, high_cutoff]/(samprate/2), 'bandpass');

struct_band_filt_EMG_trials = EMG_filt(EMG_raw_struct, b,a); 
subj_Struct.BandPass = struct_band_filt_EMG_trials;

% ###############

% SMOOTH 
% ###############
%1. Smoothing signal - Using bandpass to recrified signal
windowDuration = 3e-3; % Window duration (seconds)
struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(struct_band_filt_EMG_trials, windowDuration, samprate); 
subj_Struct.Smoothed = struct_filtSMOOTH_EMG_trials;



subj_Struct.InputBadPulses = pulsestodelete;
subj_Struct.BadPulsesCheck = wrongPulses;

% Adding method of how the data was clicked:
subj_Struct.ProcessingDetails = "low_cutoff Hz " + low_cutoff + "high_cutoff " + high_cutoff + ". Window duration: "+windowDuration ;


disp("Wrong number of pulses");
disp(wrongPulses);
%% 
dateString = datestr(now, 'mm_dd_yy');

%%% SAVING
filename_processed = "Pre_processedTEPs_" + dateString ;

save(fullfile(new_folder_SAVEPATH, filename_processed+".mat"), 'subj_Struct');
%% STEP 2: Process the PEAK TO PEAKS:

plotMethod = "BandPass";
colors = { [0 0 1 0.1],[0.9290 0.6940 0.1250], [1 0 0 0.5]};
 
final_muscles_list_fieldNames = fieldnames(subj_Struct.(plotMethod));
p2p_table = table(); 

            
for mus_i =1: length(final_muscles_list_fieldNames)


    muscle_channel = final_muscles_list_fieldNames{mus_i}; 


    % Check if this particular path has been processed:


    % Creating the muscle table that contains ALL inter, tp,
    % and pulses
    singleMuscle_table = table(); % only contains muscle specific pulses - to be added to all_struct 
    figureHandle = figure;

    trials_table = subj_Struct.(plotMethod).(muscle_channel); 

    % Iterate through each pulse - trials_table(1,:)
    total_pulses=size(trials_table,1);

    %%% Check that there are 5 pulses per intensity 
    % 5 pulses per intensity - every 10 mA
    max_intensity = ceil(total_pulses/pulses_perIntensity)*interval_mA; 



    % Defining pulse per muscle iteration variables:
    numNan = 0; % Counting the trials that return nan - after 20 mA - just stop and move on
    autofill = false;

    % There should be multiples of 5 in each intensity
    if mod(total_pulses,pulses_perIntensity) ~= 0
        disp([ muscle_channel ]);
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
    title([muscle_channel  ' - Zoom in as neccesary, decide if proceed or no MEP found'])
    hold on;
    % Create "Continue" and "Skip" buttons with the same callback function
    continueButton = uicontrol('Style', 'pushbutton', 'String', 'Continue',...
        'Position', [buttonLeft, buttonBottom + 40, buttonWidth, buttonHeight],...
        'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscle_channel));

    skipButton = uicontrol('Style', 'pushbutton', 'String', 'Skip',...
        'Position',  [buttonLeft, buttonBottom - 40, buttonWidth, buttonHeight],...
        'Callback', @(src, event) pick_Peaks_inPlot_callback(src,muscle_channel));

    % Pause execution and wait for user action
    uiwait(gcf);


    for pulseNum = total_pulses:-1:1
       intensity_value = ceil(pulseNum/pulses_perIntensity)*interval_mA;
       signal = trials_table(pulseNum,:);
      % Latency has to be found from the stim ONSET. 

       [minIDX, maxIDX, min_mV, max_mV, p2p, latency, End] = peaksAuto(signal, foundLat, minIDX_picked, maxIDX_picked);
       % For trials that find peaks before/after latency

       % Keep a counter of how mane have been return with no latency - assumes there is no mep
       if isnan(latency) 
           numNan = numNan +1;

           if numNan == 20
               autofill = true; 
           end

       elseif ~isnan(latency)
           numNan = 0;


         

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
           cell_signal = strjoin(string(signal), ', ');
          
           maxIDX_picked = NaN;
           minIDX_picked = NaN;



            new_row = table(convertCharsToStrings(filename_processed),convertCharsToStrings(muscle_channel), pulseNum, intensity_value, ...
                minIDX, maxIDX, min_mV, max_mV, p2p, latency, foundLat,  End, ...
                 maxIDX_picked,minIDX_picked );
            new_row.Data = {cell_signal};
            p2p_table = [p2p_table; new_row];


            singleMuscle_table = [singleMuscle_table; new_row];

       else
           % Create a row to save in excel file:
           new_row = table(convertCharsToStrings(filename_processed),convertCharsToStrings(muscle_channel),...
                            pulseNum, intensity_value, minIDX, maxIDX, min_mV, max_mV, p2p,...
                             latency,foundLat, End,  ...
                            maxIDX_picked,minIDX_picked ); 

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
    ALL_SUBJ_STRUCT.(muscle_channel)=singleMuscle_table;
end
%%% SAVING
filename_rc = "RecruitmentCurveTable_" + convertCharsToStrings(filename_processed) + "_" + dateString ;

save(fullfile(new_folder_SAVEPATH, filename_rc+".mat"), 'ALL_SUBJ_STRUCT');

%% PART 3
% Get RMT:

muscleRMT_Results = table();
muscle_list = fieldnames(ALL_SUBJ_STRUCT); 
for mus_i = 1:length(muscle_list)

    muscle = muscle_list{mus_i};
    subj_mus_RCdata = ALL_SUBJ_STRUCT.(muscle); % Recruitment data for subject and muscle
    % Sort the StimIntensity values
    uniqueStimIntensities = sort(unique(subj_mus_RCdata.intensity_value));

    % Iterate through the unique StimIntensity values
    for j = 1:length(uniqueStimIntensities)
        % Get the rows corresponding to the current StimIntensity
        currentStimIntensity      = uniqueStimIntensities(j);
        trialsForCurrentIntensity = subj_mus_RCdata(subj_mus_RCdata.intensity_value == currentStimIntensity, :);

        % Check how many of the P2P values are >= 0.05
        countAboveThreshold = sum(trialsForCurrentIntensity.p2p >= 0.05);

        % If 3 or more trials have P2P >= 0.05, this is the desired StimIntensity
        majority_trials_thresh = ceil(pulses_perIntensity/2);  % normally 3 out of 5 - but depedns on how many trials done
        if countAboveThreshold >= majority_trials_thresh
            % Now check for the next 2 intensities
            nextTwoValid = true; % Assume it's valid until proven otherwise
            for k = j+1:min(j+2, length(uniqueStimIntensities))
                nextStimIntensity       = uniqueStimIntensities(k);
                trialsForNextIntensity  = subj_mus_RCdata(subj_mus_RCdata.intensity_value == nextStimIntensity, :);
                countAboveThresholdNext = sum(trialsForNextIntensity.p2p >= 0.05);
                
                if countAboveThresholdNext < majority_trials_thresh
                    nextTwoValid = false; % If any of the next two intensities doesn't meet the condition, break
                    break;
                end
            end

            % If the next two intensities are valid, print the result
            if nextTwoValid
                %GET MIN AND MAX FOR EACH 
                mean_max_mv  = nanmean(trialsForCurrentIntensity.max_mV); 
                mean_min_mv  = nanmean(trialsForCurrentIntensity.min_mV); 
                mean_max_idx = nanmean(trialsForCurrentIntensity.maxIDX); 
                mean_min_idx = nanmean(trialsForCurrentIntensity.minIDX); 
                mean_lat_idx = nanmean(trialsForCurrentIntensity.latency);
                
                avg_P2P_atRMT_mV = nanmean(trialsForCurrentIntensity.p2p);
                
                % get the max matching rows:
                max_singPulse_intensity = max(uniqueStimIntensities);
                trialsForMAX_tolerance  = subj_mus_RCdata(subj_mus_RCdata.intensity_value == max_singPulse_intensity, :);
                avg_P2P_atMax_mV        = nanmean(trialsForMAX_tolerance.p2p); 
                
                % GET 21st pulse num 
                possiblePulses = sort(trialsForCurrentIntensity.pulseNum);
                first_pulseNum = possiblePulses(1); 
                
                
                newRow = {muscle, currentStimIntensity, avg_P2P_atRMT_mV, max_singPulse_intensity, avg_P2P_atMax_mV ...
                    first_pulseNum, mean_max_mv, mean_min_mv, mean_max_idx, mean_min_idx, mean_lat_idx};
                muscleRMT_Results = [muscleRMT_Results; newRow]; % Append row to the table
                
                break; % Stop once the condition is met
            end
            
        else % the current intensity checked did not meet condition >0.05 mV therefore will be saved as NaN    
            currentStimIntensity = NaN;
            first_pulseNum = NaN; 
            mean_max_mv = NaN; 
            mean_min_mv = NaN; 
            mean_max_idx = NaN; 
            mean_min_idx = NaN; 
            mean_lat_idx = NaN;
            max_singPulse_intensity = max(uniqueStimIntensities);
            avg_P2P_atRMT_mV = NaN; 
            avg_P2P_atMax_mV = NaN; 
            
            trialsForMAX_tolerance  = subj_mus_RCdata(subj_mus_RCdata.intensity_value == max_singPulse_intensity, :);
            avg_P2P_atMax_mV        = nanmean(trialsForMAX_tolerance.p2p); 
            
            newRow = {muscle, currentStimIntensity, avg_P2P_atRMT_mV, max_singPulse_intensity, avg_P2P_atMax_mV ...
                    first_pulseNum, mean_max_mv, mean_min_mv, mean_max_idx, mean_min_idx, mean_lat_idx};
            muscleRMT_Results = [muscleRMT_Results; newRow]; % Append row to the table
                
        end
    end
end
muscleRMT_Results.Properties.VariableNames = {'Muscle', 'RMT', 'avg_P2P_atRMT_mV', 'max_singlePulse_tolerance', 'avg_P2P_atMax_mV',...
    'First_pulseNum', 'mean_max_mv','mean_min_mv' , 'mean_max_idx', 'mean_min_idx', 'mean_lat_idx'};

% SAVING
rmt_filename_table = "RMT_table_" + convertCharsToStrings(filename_processed) + "_" + dateString ;

writetable(muscleRMT_Results, fullfile(new_folder_SAVEPATH, rmt_filename_table+".xlsx"));
save(fullfile(new_folder_SAVEPATH, rmt_filename_table+".mat"), 'muscleRMT_Results');



%%
% Saving PLOTs - visualization

% Plot the activation at RMT of each muscle (the 5 signals are averaged and
% PEAKSAUTO function is called to get the approx peaks of that signal)
% Shown in BIG: the average P2P and "latency", then 5 plots below with
% actual P2P. 

% Could plot the "Smoothed" so the artifact is not as big. 

% Plot maximal activation
for i = 1:height(muscleRMT_Results)
    
    % Get the intensity for the current muscle
    currentIntensity = muscleRMT_Results.RMT(i); % IF RMT 
    
    if isnan(currentIntensity) % NO RMT found - skip and dont save figure 
        
        continue;
    end
    
    muscle           = muscleRMT_Results.Muscle{i};
    first_pulseNum   = muscleRMT_Results.First_pulseNum(i);
    
    filtered_signals = subj_Struct.("BandPass").(muscle); 
    
    % Find rows in RMT table saved above where current_intensity matches the currentIntensity
    % starts row 1 = trial 1, row 40 = trial 40
    matchingRows = filtered_signals(first_pulseNum: first_pulseNum + pulses_perIntensity - 1, :);
    
    
    
    % GET MEAN SIGNAL OF 5 TRIAL - input of peaks auto to find mean peaks
    % of mean signal
    mean_signal               = mean(matchingRows);
    mean_min_idx_ofMeanSignal = muscleRMT_Results.mean_min_idx(i);
    mean_max_idx_ofMeanSignal = muscleRMT_Results.mean_max_idx(i);
    mean_latency              = muscleRMT_Results.mean_lat_idx(i);
    % find relative max peaks :
    [minIDX_calcMEAN, maxIDX_calcMEAN, min_mV_calcMEAN, max_mV_calcMEAN,...
        p2p_calcMEAN, latency_calcMEAN, End_calcMEAN] = peaksAuto(mean_signal, round(mean_latency), round(mean_min_idx_ofMeanSignal), round(mean_max_idx_ofMeanSignal));
      
    % get the time vector and indices in time (ms)
    timeVector                   = 1000*(0:length(mean_signal)-1) / samprate; %ms
    maxIDX_calcMEAN_TIMEms       = 1000*maxIDX_calcMEAN/samprate; 
    minIDX_calcMEAN_TIMEms       = 1000*minIDX_calcMEAN/samprate;
    mean_latency_TIMEms          = 1000*latency_calcMEAN/samprate;
    % Create a figure - shows average activation and then the 5 trials for
    % that "RMT"
    disp(muscle)
    disp(['input lat: ' num2str(round(mean_latency)) '. calc lat: ' num2str(latency_calcMEAN)]);
    disp([num2str(abs((round(mean_latency)-latency_calcMEAN)))]); 
    
    
    % Plotting
    
    
    % Figure for individual muscles: 
    rmt_ind_figure = figure;
    
    figure(rmt_ind_figure); 
    subplot(2,pulses_perIntensity,[1 pulses_perIntensity]);
    plot( mean_signal, "black");
    % Plot latencies and min/max
    % If Nan
    try
        hold on;
        xline(latency_calcMEAN); 
    catch
    end
    try
        hold on;  
    
        plot(minIDX_calcMEAN,min_mV_calcMEAN, 'x')
        hold on; 
    
        plot(maxIDX_calcMEAN, max_mV_calcMEAN, 'x')
    catch
    end
    title([ muscle ', RMT: ' num2str(currentIntensity)]);
    ylabel('mV');
    xlabel('Index (to get time in ms = index*0.5)');

 
    % Individual trials:
    % For loop to create 5 subplots in the second row
    %####### first_pulseNum input
    trial_intensity_actualPulseNum = first_pulseNum; % this might change depending on which one want to plot
    
    for iii = 1:pulses_perIntensity
        
        figure(rmt_ind_figure); 
        subplot(2,pulses_perIntensity,pulses_perIntensity + iii); % Positions 6 to 10 in a 2x5 grid ( if pulses_perIntensity=5)
        plot( matchingRows(iii,:)) % Replace with your desired plot data for each subplot
        
        % Find peak to peak:
        temp_table_trial = ALL_SUBJ_STRUCT.(muscle)(ALL_SUBJ_STRUCT.(muscle).pulseNum == trial_intensity_actualPulseNum,:);
        if temp_table_trial.p2p >= 0.05
            
            temp_min_TIMEms = 1000*temp_table_trial.minIDX/samprate; 
            temp_max_TIMEms = 1000*temp_table_trial.maxIDX/samprate;
            temp_min_idx    = temp_table_trial.minIDX; 
            temp_max_idx    = temp_table_trial.maxIDX;
            temp_lat_idx    = temp_table_trial.latency;
            
            temp_min_mV     = temp_table_trial.min_mV;
            temp_max_mV     = temp_table_trial.max_mV;
            
            hold on; 
            plot(temp_min_idx,temp_min_mV, 'x')
            hold on; 
            plot(temp_max_idx, temp_max_mV, 'x')
            try % maybe latency was not found
                hold on;
                xline(temp_lat_idx)
            catch
            end
        end 
        
        % same y axis on row 2:
        ylim([min(min(matchingRows)), max(max(matchingRows))]);
        title(['Trial # ' num2str(iii)]);
        trial_intensity_actualPulseNum = trial_intensity_actualPulseNum+1;
       
    end
    % SAVING FIGURE.
    figure_name_ind_RMT = muscle+"_RMT_" + num2str(currentIntensity)+"mA"; 
    % Save as .mat file
    savefig(rmt_ind_figure, fullfile(new_folder_SAVEPATH_FIGRUES_MATLAB, figure_name_ind_RMT+ ".fig"));

    % Save as .png file
    saveas(rmt_ind_figure, fullfile(new_folder_SAVEPATH_FIGRUES, figure_name_ind_RMT+ ".png"));
end

%% Single subplot for all muscles 
% ORDER OF SUBPLOTS RIGHT AND LEFT MATCHED:
% Create the dictionary using containers.Map
if lower_extremity == true
    muscle_dict = containers.Map();

    % Add the muscle names as keys and their corresponding values
    muscle_dict('RHAM') = 1;
    muscle_dict('RRF') = 3;
    muscle_dict('RMG') = 7;
    muscle_dict('RTA') = 9;
    muscle_dict('RVL') = 5;
    muscle_dict('LHAM') = 2;
    muscle_dict('LRF') = 4;
    muscle_dict('LMG') = 8;
    muscle_dict('LTA') = 10;
    muscle_dict('LVL') = 6;
end


subplot_all = figure;


for i = 1:height(muscleRMT_Results)
    
    % Get the intensity for the current muscle
    currentIntensity = muscleRMT_Results.RMT(i); % IF RMT 
    
    if isnan(currentIntensity) % NO RMT found - skip and just plot the maxs. 
        % need to either plot the LAST current intensity / tolerance 
    end
    
    muscle           = muscleRMT_Results.Muscle{i};
    filtered_signals = subj_Struct.("BandPass").(muscle); 
    total_pulses = size(filtered_signals,1); 
    
    for pulseNum = 1:total_pulses
        signal = filtered_signals(pulseNum,:);

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
        if lower_extremity == true
            subplot(5,2, muscle_dict(muscle));
        else
            subplot(5,2, i);
        end
        plot(signal, 'Color', currentColor)
        
        hold on  
    end
    if i == 5
        ylabel('Amplitude (mV)')
    end
    title([muscle + ". RMT: " + num2str(currentIntensity) + "mA" ]);
end
% SAVING
figure_name = "All_10_muscles_subplot" ; 
% Save as .mat file
savefig(subplot_all, fullfile(new_folder_SAVEPATH_FIGRUES_MATLAB, figure_name+ ".fig"));

% Save as .png file
saveas(subplot_all, fullfile(new_folder_SAVEPATH_FIGRUES, figure_name+ ".png"));

%% Figure - recruitment curve:
subplot_rc_all = figure;


for i = 1:height(muscleRMT_Results)
    
    % Get the intensity for the current muscle
    currentIntensity = muscleRMT_Results.RMT(i); % IF RMT 
    
    if isnan(currentIntensity) % NO RMT found - skip and just plot the maxs. 
        % need to either plot the LAST current intensity / tolerance 
    end
    
    muscle           = muscleRMT_Results.Muscle{i};
    filtered_signals = ALL_SUBJ_STRUCT.(muscle); 
    
    p2p_array = filtered_signals.p2p;
    % replace nan with 0
    p2p_array(isnan( p2p_array)) = 0;
    intensity_array = filtered_signals.intensity_value;
    
    if muscle(1) == 'L'
        currentColor = "red";
    else 
        currentColor ="blue";
    end
     % Set order
     

     % Plot signal
    if lower_extremity == true
        subplot(5,2, muscle_dict(muscle));
    else
        subplot(5,2, i);
    end
    plot(intensity_array,p2p_array , 'o','Color', currentColor)
    hold on;
    xline(currentIntensity);
    if i == 5
        ylabel('Peak to peak amplitude (mV)')
    end
   % ylim([0,max(muscleRMT_Results.avg_P2P_atMax_mV) ])
    title([muscle + ". RMT: " + num2str(currentIntensity) + "mA" ]);
end
%SAVING

figure_name = "All_10_muscles_recruitmentCurve_subplot" ; 
    % Save as .mat file
savefig(subplot_rc_all, fullfile(new_folder_SAVEPATH_FIGRUES_MATLAB, figure_name+ ".fig"));

% Save as .png file
saveas(subplot_rc_all, fullfile(new_folder_SAVEPATH_FIGRUES, figure_name+ ".png"));



