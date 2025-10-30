% Smers pipeline pre preocessing:
% From Labchart exported .mat file
% FILL IN BAD PULSES IN TEPS_LOG.xlsx
% To struct containing:
% - Raw segmented time signal per trial
% Filtered
% Centered and demeaned (After filtered)
% Aligned/shifted ( sometimes the delsys sends the trigger late ~45
% points, 22 ms)
% Saved to participant

subj_path_suffix = config.SUBJ_PATH_SUFFIX;
TEPcolNames = config.TEPS_LOG_COLUMN_NAMES;
prePostColNameHeader = TEPcolNames.PRE_POST_COLUMN;
tepFileNameHeader = TEPcolNames.TEP_FILENAME;
subjectNameHeader = TEPcolNames.SUBJECT_NAME;
pareticSideHeader = TEPcolNames.PARETIC_SIDE;
sessionCodeHeader = TEPcolNames.SESSION_CODE;
pulsesToDeleteHeader = TEPcolNames.PULSES_TO_DELETE;
timepointHeader = TEPcolNames.TIMEPOINT;
final_muscles_list = convertCharsToStrings(config.MUSCLES);
pulses_perIntensity = config.NUM_PULSES_PER_INTENSITY;

% Lowpass filter config
lowpassFilterConfig = config.LOWPASS_FILTER;
low = lowpassFilterConfig.LOWPASS_CUTOFF; % [Inanici, 2018]
% Don't do highpass filter, it adds low-freq distortion [Inanici, 2018]
samprate = config.SAMPLE_RATE;
lowpassOrder = lowpassFilterConfig.ORDER;
[f,e] = butter(lowpassOrder,low/(samprate/2),'low');

% Bandpass filter config
bandpassFilterConfig = config.BANDPASS_FILTER;
%A. Bandpass filter design (20-500 Hz)
low_cutoff = bandpassFilterConfig.LOW_CUTOFF;  % Lower cutoff frequency (Hz)
high_cutoff = bandpassFilterConfig.HIGH_CUTOFF; % Upper cutoff frequency (Hz)
bandpassOrder = bandpassFilterConfig.ORDER;
[b, a] = butter(bandpassOrder, [low_cutoff, high_cutoff]/(samprate/2), 'bandpass');


%% Read in master TEPs file. Removes extra rows
% Obtains the bad pulses for each MEP trial.
teps_log_filename = fullfile(subj_path, 'TEPs_log.xlsx');
[~,~,teps_log] = xlsread(teps_log_filename,'Sheet1');
isNumericNaN = @(x) isnumeric(x) && isnan(x); % Anonymous function
nanSubjIdx = cellfun(isNumericNaN, teps_log(:,1));
firstNaNSubjIdx = find(nanSubjIdx,1,'first');
teps_log = teps_log(1:firstNaNSubjIdx-1,:);
header_row = teps_log(1,:);
prePostColNameIdx = ismember(header_row, prePostColNameHeader);
tepFileNameIdx = ismember(header_row, tepFileNameHeader);
subjectNameIdx = ismember(header_row, subjectNameHeader);
pareticSideIdx = ismember(header_row, pareticSideHeader);
sessionCodeIdx = ismember(header_row, sessionCodeHeader);
pulsesToDeleteIdx = ismember(header_row, pulsesToDeleteHeader);
timepointIdx = ismember(header_row, timepointHeader);

%% START ITERATION
missingFiles = {};
wrongPulses = {};
SUBJ = subject;
curr_subj_path = fullfile(subj_path_prefix, SUBJ, subj_path_suffix);
curr_subj_save_path = fullfile(subj_save_path_prefix, SUBJ, subj_path_suffix);

% Create folder to save mats if do not exist
% Define the new folder path
folderPath = fullfile(curr_subj_save_path, 'TEPsProcessed');

% Check if the folder exists, and create it if it doesn't
if ~exist(folderPath, 'dir')
    mkdir(folderPath);
    fprintf('Folder "%s" created successfully.\n', folderPath);
else
    fprintf('Folder "%s" already exists.\n', folderPath);
end


for INTER_i = 1: length(INTER_list)
    INTER = INTER_list{INTER_i};
    inter_path = fullfile(curr_subj_path, INTER);
    matFiles = dir(fullfile(inter_path, '*.mat'));

    % Extract the file names and display them
    fileNames = {matFiles.name};  % Create a cell array of file names
    foundPre = false;
    foundPost= false;

    % RESET THE SUBJ STRUCT FOR EACH INTERVENTION AND TIMEPOINT
    subjStruct = struct();
    for k = 1:length(matFiles) % this is pre post
        fileName = matFiles(k).name;
        if contains(lower(fileName), 'pre')
            foundPre = true;  % Found pre file
        elseif contains(lower(fileName), 'post')
            foundPost = true;  % Found post file
        end

        %% Get row from TEPs log to process
        % Identify row of interest - matches clicked name to the name written in
        % the TEPs_log
        filename_row_num = strcmp(teps_log(:,tepFileNameIdx), fileName);
        subj_tepsLog_row = teps_log(filename_row_num, :);

        % Get subject - print all details
        subj = subj_tepsLog_row{subjectNameIdx};
        paretic_side = subj_tepsLog_row{pareticSideIdx};
        timepoint = subj_tepsLog_row{prePostColNameIdx};
        session_code = subj_tepsLog_row{sessionCodeIdx};
        pulsestodelete = subj_tepsLog_row{pulsesToDeleteIdx};

        disp([num2str(subj), ' ', timepoint, ' - ', session_code])

        % CHECK IF FILES EXISTS AND IF IT DOES SKIP:
        processed_files = dir(fullfile(curr_subj_save_path,"TEPsProcessed", '*.mat'));
        if sum(contains({processed_files.name}, "A_" +SUBJ  +"_pre_processedTEPs_"))
            disp("*************A_" + SUBJ + "_" + mapped_interventions(session_code) + " already processed");
            return
        end

        %% Processing parameters
        number_of_muscles = length(final_muscles_list);

        %% ###############################################
        % Opening file

        load(fullfile(inter_path, fileName));

        delete_in = getBadPulses(pulsestodelete);


        %% ###############################################
        % Establish channels and processing mat file


        % Find rows that contain RVL, LRV, STIM, and KNEE to delete
        emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];

        % Final set of titles
        titles(emptyrow_title_in,:) = [];
        % Final rows of data
        datastart(emptyrow_title_in,:) = [];

        % Get the order of channels presented in the mat file
        channels = cell(number_of_muscles,1);
        for channel_num = 1:number_of_muscles
            channels{channel_num} = strtrim(titles(channel_num,:)); % gives order of channels in the data
        end

        %% Correcting the channels namings that were mislabeled:
        channels_struct_from_json = jsondecode(fileread('A_channels.json'));
        if ismember(SUBJ, fieldnames(channels_struct_from_json))
            if ismember(INTER, fieldnames(channels_struct_from_json.(SUBJ)))
                channels = channels_struct_from_json.(SUBJ).(INTER);
            end
        end

        %% Creating the structs of filtered data
        EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Raw = EMG_raw_struct;

        % CHECK PULSES (RANDOM MUSCLE)
        total_pulses=size(EMG_raw_struct.RHAM,1);
        
        if mod(total_pulses,pulses_perIntensity) ~= 0
            disp(strcat(subj , " ", session_code  , " ",timepoint));
            disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
            % ADD TO ERROR LIST:
            disp(delete_in);
            wrongPulses{end + 1} = strcat(subj , " ", session_code  , " ",timepoint, " tot pulses " , num2str(total_pulses));
        end        

        % LOWPASS
        struct_low_filt_EMG_trials = EMG_filt(EMG_raw_struct, f,e);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).LowPass = struct_low_filt_EMG_trials;        

        % BANDPASS
        struct_band_filt_EMG_trials = EMG_filt(EMG_raw_struct, b,a);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).BandPass = struct_band_filt_EMG_trials;

        % ###############
        %1. Shifting signal to last reference (just the bandpass):
        [struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(struct_band_filt_EMG_trials);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Aligned_fromBand = struct_EMG_trials_shift_fromBand;
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromBand = struct_EMG_trials_shiftIDX;
        % if index is negative - have to shift forward
        % #####
        %2. RECTIFY SIGNAL - Using bandpass to recrified signal

        musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
        for channel_num = 1:numel(musc_fieldnames)
            muscle = musc_fieldnames{channel_num};
            muscles_trials = struct_EMG_trials_shift_fromBand.(muscle);
            rect_struct.(muscle) = abs(muscles_trials);
        end
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligBandOnly = rect_struct;

        %.4 Stim ONSET
        struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(struct_band_filt_EMG_trials);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;

        % SMOOTH INTERMEDIATE STEP BEFORE ALGIN
        % ###############
        %1. Smoothing signal - Using bandpass to recrified signal
        windowDuration = 3e-3; % Window duration (seconds)
        struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(struct_band_filt_EMG_trials, windowDuration, samprate);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Smoothed = struct_filtSMOOTH_EMG_trials;

        % ###############
        %2. Shifting signal to last reference:
        [struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Aligned_fromSmooth = struct_EMG_trials_shift_fromSmooth;
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).AlignedShiftIdx_fromSmooth = struct_EMG_trials_shiftIDX;


        % #####
        %3. RECTIFY SIGNAL - Using bandpass to recrified signal

        musc_fieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
        for channel_num = 1:numel(musc_fieldnames)
            muscle = musc_fieldnames{channel_num};
            muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle);
            rect_struct.(muscle) = abs(muscles_trials);
        end
        subj_Struct.(SUBJ).(mapped_interventions(session_code)).(timepoint).Rectified_afterAligSmooth = rect_struct;

    end


    % Check which files are missing and update the list
    if ~foundPre
        missingFiles{end + 1} = INTER + "_pre";
    end
    if ~foundPost
        missingFiles{end + 1} = INTER + "_post";
    end



end

subj_Struct.(SUBJ).Missing = missingFiles;
subj_Struct.(SUBJ).BadPulsesCheck = wrongPulses;
% Adding method of how the data was clicked:
subj_Struct.(SUBJ).ProcessingDetails = "low_cutoff Hz " + low_cutoff + "high_cutoff " + high_cutoff + ". Window duration: "+windowDuration + ". Bandpass then either align and rectify like that, or smooth and then align and rectify";



disp("Missing mat files::")
disp(missingFiles)

disp("Wrong number of pulses");
disp(wrongPulses);

SAVEPATH = fullfile(curr_subj_save_path, "TEPsProcessed", "A_" +SUBJ  +"_pre_processedTEPs_"+datestr(now, 'ddmmmyyyy')+ ".mat");
save(SAVEPATH, "subj_Struct")
%%








%% PLOTTING:
% musc_fieldnames = fieldnames(struct_EMG_trials_shift);
%     for channel_num = 1:numel(musc_fieldnames)
%         muscle = musc_fieldnames{channel_num};
%
%         muscles_trials = EMG_raw_struct.(muscle);
%         figure;
%         subplot(4,1,1);
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%
%             plot(sig);
%             hold on;
%         end
%         title([muscle '- Raw'])
%
%         muscles_trials = struct_band_filt_EMG_trials.(muscle);
%         subplot(4,1,2)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%
%             plot(sig);
%             hold on;
%         end
%         title('BandPass')
%
%
%         muscles_trials = struct_EMG_trials_shift.(muscle);
%         subplot(4,1,3)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%
%             plot(sig);
%             hold on;
%         end
%         title('Aligned')
%
%
%         muscles_trials = struct_EMG_trials_shift.(muscle);
%         muscles_trials = abs(muscles_trials);
%         subplot(4,1,4)
%         for pulsenum = 1:size(muscles_trials,1)
%             sig = muscles_trials(pulsenum, :);
%
%             plot(sig);
%             hold on;
%         end
%         title('Rect')
%
%     end
%

%% PLOTTING ALIGNED SIGNALS AND SHIFTED
% sig_idx1 = 34;
% sig_idx2=75;
% muscle = 'RTA';
% first_Sig = subj_Struct.SS05.RMT30.POST.BandPass.(muscle)(sig_idx1,:);
% last_sig = subj_Struct.SS05.RMT30.POST.BandPass.(muscle)(sig_idx2,:);
%
%
% % shifts
% shfit_amount = subj_Struct.SS05.RMT30.POST.AlignedShiftIdx.(muscle)(sig_idx1,1);
% max_corr_idx = subj_Struct.SS05.RMT30.POST.AlignedShiftIdx.(muscle)(sig_idx1,2);
% shifted_Sig = subj_Struct.SS05.RMT30.POST.Aligned.(muscle)(sig_idx1,:);
%
% figure
% plot(first_Sig )
% hold on
% plot(last_sig)
% hold on
% try
%     xline(shfit_amount + length(first_Sig));
%
%     % plot the shifted signal
%     hold on;
%     plot(shifted_Sig);
%     legend('signal pre shift', 'reference last signal','max corr', 'shifted sig');
% catch
%     disp('no shift');
% end
%
%
% figure()
% plot(first_Sig);hold on; plot(shifted_Sig);
% legend('signal pre shift','shifted sig');
%
%%
% plot to see differences:
% figure
% p = 2;
% plot(subj_Struct.SS01.RMT30.PRE.BandPass.RVL(p,:))
% hold on
% plot(subj_Struct.SS01.RMT30.PRE.Smoothed.RVL(p,:))
%
% legend("Bandpass - input", "Smoothed")
%
%
%
% figure
% plot(subj_Struct.SS01.RMT30.PRE.Rectified_afterAligBandOnly.RVL(p,:))
% hold on
% plot(subj_Struct.SS01.RMT30.PRE.Rectified_afterAligSmooth.RVL(p,:))
%
% legend("Bandpass - input", "Smoothed")

