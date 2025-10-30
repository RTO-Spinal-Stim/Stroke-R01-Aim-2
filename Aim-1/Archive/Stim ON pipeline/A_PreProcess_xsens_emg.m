interventionLists = jsondecode(fileread('intervention_list.json'));
if ismember(SUBJ,fieldnames(interventionLists))
    interventionList = interventionLists.(SUBJ);
else
    interventionList = interventionLists.DEFAULT;
end


% File naming conventions:
% "intervention" _ STIM _ walk _ "#"
sensor_subfolders = {'EMG', 'XSENS'};

upper_leg_list = {'RHAM', 'RRF', 'RVL', 'LHAM', 'LRF', 'LVL'};


% Sampling frequencies
EMG_Fs = 2000;
X_Fs = 100;



%walkNum = 2; % walk number changes ---- depending on the
%filename =  interventionList{1} + "_STIM_walk_" + num2str(walkNum);

% EMG FILES
delsys_files = dir(fullfile(subject_load_path, "EMG", '*.mat'));
walk_files_EMG = {delsys_files(contains({delsys_files.name}, 'walk')&contains({delsys_files.name}, 'STIM')).name};


% XSENS FILES
XSENS_files = dir(fullfile(subject_load_path, "XSENS", '*.xlsx'));
walk_files_XSENS = {XSENS_files(contains({XSENS_files.name}, 'walk')&contains({XSENS_files.name}, 'STIM')).name};

% To keep track of signals that dont look good after filtering
global flagged_indices;
flagged_indices = {};

%%
walks_struct = struct();
% Table keeping track of walks and filenames:
walk_filename_dict = table('Size', [0, 3], 'VariableTypes', {'int32', 'string', 'string'}, 'VariableNames', {'WalkNum', 'Filename_EMG', 'Filename_XSENS'});

% Data file checks
assert(length(walk_files_EMG)==length(walk_files_XSENS));
% Get the highest number from the walks
maxWalkNum = 0;
for i=1:length(walk_files_EMG)
    parts = strsplit(walk_files_EMG{i},'_');
    currentNum = str2double(regexp(parts{end}, '\d+', 'match', 'once'));
    if currentNum > maxWalkNum
        maxWalkNum = currentNum;
    end
end
%%
for walk_file_num = 1:maxWalkNum % there should be 11 walk file names
    
    walk_file_idx = contains(walk_files_EMG, "walk_"+num2str(walk_file_num)+".mat");    
    if ~any(walk_file_idx)
        walk_filename_dict = [walk_filename_dict; {walk_file_num, missing, missing}];
        continue;
    end
    file_name_EMG = walk_files_EMG{walk_file_idx};
    emg_filename = file_name_EMG;
    disp(['EMG:   ' emg_filename]);
    EMG_PATH = fullfile(subject_load_path,"EMG", emg_filename );
    emg_raw_struct = load(EMG_PATH);
    
    titles = emg_raw_struct.titles;
    % TODO: What is this doing?
    emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows')) find(ismember(titles,'Stim Trig','rows'))];
    
    % Final set of titles
    titles(emptyrow_title_in,:) = [];
    % Final rows of data
    emg_raw_struct.datastart(emptyrow_title_in,:) = [];
    emg_raw_struct.dataend(emptyrow_title_in,:) = [];
    
    number_of_muscles = length(titles);
    % Get the order of channels presented in the mat file
    muscles = cell(number_of_muscles,1);
    for channel_num = 1:number_of_muscles
        muscles{channel_num} = strtrim(titles(channel_num,:)); % gives order of channels in the data
    end
    global plot_status;
    plot_status = false;
    for i = 1:length(muscles)
        start   = emg_raw_struct.datastart(i);
        endData = emg_raw_struct.dataend(i);
        if start == -1
            continue;
        end
        walks_struct.EMG.RAW.("Walk_"+num2str(walk_file_num)).(muscles{i}) = emg_raw_struct.data(start:endData);


        % Save filtered EMG:
        % CALL FILTERING PIPELINE FUNCTION:
        upperLegs = ismember(muscles{i}, upper_leg_list); % Check if processing upper leg or lower leg muscles
        % Getting the frequency :
        parts = split(emg_filename, '_');

        % Extract the first part and extract the number
        first_part = parts{1}; % Get the first part as a character vector
        frequency = str2double(regexp(first_part, '\d+', 'match', 'once')); % Extract the number

        if isnan(frequency)
            frequency = 0;
        end
        [final_signal, emg_bandpass] = filtering_pipelineFunction(emg_raw_struct.data(start:endData),upperLegs, frequency);
        % For sham trials and lower leg muscles - final_signal = emg_bandpass since a
        % notch filter WAS NOT applied

        walks_struct.EMG.FILTERED.("Walk_"+num2str(walk_file_num)).(muscles{i}) = final_signal;

        if plot_status == true
            % Double check with plots here
            fig = figure('Position', [100, 100, 800, 600]);

            L = length(emg_bandpass);
            time_vector = (0:L-1)/EMG_Fs;
            % Subplot 1: plots - emg_bandpass
            subplot(2,1,1)
            plot(time_vector,emg_bandpass);
            title(sprintf('Bandpassed filtered'));
            xlabel('Time (s)');
            ylabel('Amplitude');

            % Subplot 2: plots - final_signal
            subplot(2, 1, 2);
            plot(time_vector,final_signal, 'Color', 'b');
            title(sprintf('Notch filtered'));
            xlabel('Time (s)');
            ylabel('Amplitude');

            trial_name = strjoin({emg_filename, muscles{i}, num2str(frequency)}, ' ');
            sgtitle(trial_name);

            % "Looks Good" Button
            uicontrol('Style', 'pushbutton', 'String', 'Looks Good', ...
                'Position', [200, 5, 100, 40], ...
                'BackgroundColor', [0, 1, 0.1], ... % green
                'Callback', @(~,~) close(fig)); % if it is okay, just close fig and move on to the next one

            % "Flag" Button

            uicontrol('Style', 'pushbutton', 'String', 'Flag', ...
                'Position', [500, 5, 100, 40], ...
                'BackgroundColor', [0.8, 0.1, 0], ... % red
                'Callback', @(~,~) flag_signal(fig, trial_name));

            % "Skip" Button - stop plottin
            uicontrol('Style', 'pushbutton', 'String', 'Skip', ...
                'Position', [700, 550, 80, 30], ... % Upper right corner
                'Callback', @(~,~) skip_signal(fig));



            uiwait; % Wait for figure to close before continuing
        end
    end
    
    % XSENS files:
    walk_file_xsens_idx = contains(walk_files_XSENS, "walk_"+num2str(walk_file_num)+".xlsx");        
    if ~any(walk_file_xsens_idx)
        walk_filename_dict = [walk_filename_dict; {walk_file_num, missing, missing}];
        continue;
    end
    file_name_XSENS = walk_files_XSENS{walk_file_xsens_idx};
    xsens_file = file_name_XSENS;
    disp(['XSENS: ' xsens_file]);
    XSENS_PATH = fullfile(subject_load_path,"XSENS", xsens_file );

    %sheets_list = ["Joint Angles XZY", "Segment Orientation - Quat", "Sensor Orientation - Quat", "Segment Position"];

    temp_struct.(matlab.lang.makeValidName("Segment Position")) = xlsread(XSENS_PATH, "Segment Position");
    temp_struct.(matlab.lang.makeValidName("Segment Orientation - Quat")) = xlsread(XSENS_PATH, "Segment Orientation - Quat");


    pel_ori_segment = temp_struct.("SegmentOrientation_Quat")(:, 2:5);

    pel_pos         = temp_struct.("SegmentPosition")(:,2:4);
    rightFoot_pos   = temp_struct.("SegmentPosition")(:,53:55);
    leftFoot_pos    = temp_struct.("SegmentPosition")(:,65:67);

    [L_hs, R_hs, Pos_Rf, Pos_Lf] = get_heelstrikes(pel_ori_segment, pel_pos, rightFoot_pos, leftFoot_pos);

    % Plot :
    if plot_status==true
        plot_heelstrikes_xsens(Pos_Lf, L_hs,Pos_Rf, R_hs  );
        title(["Foot trajec " + xsens_file], 'Interpreter','none' );
    end

    L_hs_label = array2table(L_hs, 'VariableNames', {'start_xsensIDX', 'end_xsensIDX'});
    L_hs_label.leg_side = repmat("L", height(L_hs_label), 1);

    R_hs_label = array2table(R_hs, 'VariableNames', {'start_xsensIDX', 'end_xsensIDX'});
    R_hs_label.leg_side = repmat("R", height(R_hs_label), 1);

    combined_heelstrikes = [L_hs_label; R_hs_label];
    combined_heelstrikes = sortrows(combined_heelstrikes,"start_xsensIDX");

    % Convert to EMG index
    scaling_factor = EMG_Fs / X_Fs; % 2000/100 , 100 to 2000,  multiply by 20
    combined_heelstrikes.start_emgIDX = combined_heelstrikes.start_xsensIDX * scaling_factor;
    combined_heelstrikes.end_emgIDX = combined_heelstrikes.end_xsensIDX * scaling_factor;

    % This saves all the indices obtianed from XSENS for the specific
    % trial

    clear temp_struct
    walks_struct.XSENS.("Walk_"+num2str(walk_file_num)) = combined_heelstrikes;
    
    
    walk_filename_dict = [walk_filename_dict; {walk_file_num, emg_filename, xsens_file}];
    % ADD THIS TABLE TO FINAL STRICT
    
end
walks_struct.WalksDictionary = walk_filename_dict;
walks_struct.FlaggedFilter = flagged_indices;

% Save structure:
save(fullfile(subject_save_path,'A_xsens_delsys_processed.mat'), 'walks_struct');

%% Plotting filtering:
muscle = "LHAM";
if plot_status==true
    figure
    subplot(2,1,1)
    plot(walks_struct.EMG.RAW.Walk_1.(muscle))
    subplot(2,1,2)
    plot(walks_struct.EMG.FILTERED.Walk_1.(muscle))
end



% Function to handle "Skip" button action
function skip_signal(fig)
global plot_status;
plot_status = false; % Set plot_status to false
disp('Signal check skipped.');
close(fig); % Close the figure
end
