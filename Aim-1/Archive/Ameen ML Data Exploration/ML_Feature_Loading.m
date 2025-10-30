clear
clc

% Define the filename
csvFileName = 'MLresults.csv';

% Check if the file exists before loading
if isfile(csvFileName)
    % Load the table if the file exists
    resultsTable = readtable(csvFileName);
    disp('Loaded existing results table.');
else
    % Initialize an empty table if the file does not exist
    disp('No existing results table found. Initializing a new table.');
    resultsTable = table();
end       

% Initialize the waitbar
%h = waitbar(0, 'Please wait...');
%cleanupObj = onCleanup(@() close(h)); % Ensure the waitbar closes if there's an error

% Define the total number of checkpoints
%total_checkpoints = 10;

%try

% Select subject folder
subjectFolder = uigetdir('', 'Select subject folder');
if subjectFolder == 0
    disp('Operation canceled.');
    return;
end

% Extract folder name from the path
[~, folderName, ~] = fileparts(subjectFolder);

% Create a struct with dynamic field names
folderStruct = struct();

% Assign an empty struct to the dynamic field
folderStruct.(folderName) = struct(); 

% Define subfolder names
subfolders = {'Delsys', 'Gaitrite', 'XSENS'}; 
interventionFolders = {'30_RMT', '30_TOL', '50_RMT', '50_TOL','SHAM2'};

% Define a mapping between folder names and struct field names
folderMap = containers.Map(interventionFolders, ...
                           {'RMT30', 'TOL30', 'RMT50', 'TOL50','SHAM2'});

% Define the file extensions for each subfolder type
fileExtensions = {'*.mat', '*.xlsx', '*.xlsx'};

% Iterate over intervention folders
for i = 1:length(interventionFolders)
    % Use the mapping to get the correct struct field name
    interventionStructName = folderMap(interventionFolders{i});
    
    % Initialize sub-struct for the intervention folder
    folderStruct.(folderName).(interventionStructName) = struct();
    
    % Iterate over subfolders
    for j = 1:length(subfolders)
        subfolder = subfolders{j};
        
        % Initialize a struct for each subfolder
        folderStruct.(folderName).(interventionStructName).(subfolder) = struct();
        
        % Construct the path to the files
        filesPath = fullfile(subjectFolder, subfolder, interventionFolders{i}, fileExtensions{j});
        files = dir(filesPath);
        
        % Load the data based on file type
        for k = 1:length(files)
            % Load .mat files for 'Delsys'
            if strcmp(subfolder, 'Delsys') && ~isempty(files(k).name)
                data = load(fullfile(files(k).folder, files(k).name));
                % Store the data in a struct with the file name as the field
                fieldName = matlab.lang.makeValidName(files(k).name);
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName) = data;
            % Load .xlsx files for 'Gaitrite' and 'XSENS'
            elseif any(strcmp(subfolder, {'Gaitrite', 'XSENS'})) && ~isempty(files(k).name)
                
                    if strcmp(subfolder, 'XSENS')
                        % For XSENS files, load the 'Joint Angles XZY' sheet
                        [num, txt, raw] = xlsread(fullfile(files(k).folder, files(k).name), 'Joint Angles XZY');
                    else
                        % For Gaitrite files
                        [num, txt, raw] = xlsread(fullfile(files(k).folder, files(k).name));
                    end
               
                % Store the data in a struct with the file name as the field
                fieldName = matlab.lang.makeValidName(files(k).name);
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).num = num;
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).txt = txt;
                folderStruct.(folderName).(interventionStructName).(subfolder).(fieldName).raw = raw;
            end
        end
    end
end

%%

addpath('Y:\Spinal Stim_Stroke R01\AIM 1\CODE');


intervention = fieldnames(folderStruct.(folderName));

for e = 1:length(intervention)
    % Load EMG Data
    EMGStruct = folderStruct.(folderName).(intervention{e}).Delsys;
    folderStruct.(folderName).(intervention{e}).loadedDelsys = loadMatFiles(EMGStruct);

end

%waitbar(2/total_checkpoints, h, 'Loaded EMG Complete');


for g = 1:length(intervention)
    % Load EMG Data
    GaitStruct = folderStruct.(folderName).(intervention{g}).Gaitrite;
    folderStruct.(folderName).(intervention{g}).loadedGaitrite = loadExcelFiles(GaitStruct);

end

%waitbar(3/total_checkpoints, h, 'Loaded Gaitrite Complete');

for x = 1:length(intervention)
    % Load EMG Data
    XsensStruct = folderStruct.(folderName).(intervention{x}).XSENS;
    folderStruct.(folderName).(intervention{x}).loadedXSENS = loadExcelFiles(XsensStruct);

end

%% Pre-Process DATA

EMG_Fs = 2000; %Delsys sampling freq
GAIT_Fs = 120;
X_Fs = 100;
% Call the function to apply the ACSR filter
% filteredData = applyACSRFilter(allEMGData, Fs);

for f = 1:length(intervention)
EMGStruct = folderStruct.(folderName).(intervention{f}).loadedDelsys;
%Pre-Process EMG Data
folderStruct.(folderName).(intervention{f}).filteredEMG = preprocessEMG(EMGStruct, EMG_Fs);                                                                                                                                                                                                                                                                                                                                                                               
end

%waitbar(5/total_checkpoints, h, 'Filtered EMG Complete');

for g = 1:length(intervention)
gaitStruct = folderStruct.(folderName).(intervention{g}).loadedGaitrite;
%Process GAITRite Data
folderStruct.(folderName).(intervention{g}).processedGait = processGAITRite_Cycle(gaitStruct,GAIT_Fs, EMG_Fs, X_Fs);
end



%% Organize and Restructure Data
for x = 1:length(intervention)
    
organizedData.(folderName).raw.(intervention{x}).Delsys  = folderStruct.(folderName).(intervention{x}).Delsys;
organizedData.(folderName).raw.(intervention{x}).Gaitrite  = folderStruct.(folderName).(intervention{x}).Gaitrite;
organizedData.(folderName).raw.(intervention{x}).XSENS  = folderStruct.(folderName).(intervention{x}).XSENS;

organizedData.(folderName).processed.(intervention{x}).loadedDelsys  = folderStruct.(folderName).(intervention{x}).loadedDelsys;
organizedData.(folderName).processed.(intervention{x}).loadedGaitrite  = folderStruct.(folderName).(intervention{x}).loadedGaitrite;
organizedData.(folderName).processed.(intervention{x}).loadedXSENS  = folderStruct.(folderName).(intervention{x}).loadedXSENS;
organizedData.(folderName).processed.(intervention{x}).filteredEMG  = folderStruct.(folderName).(intervention{x}).filteredEMG;
organizedData.(folderName).processed.(intervention{x}).processedGait  = folderStruct.(folderName).(intervention{x}).processedGait;

end

for x = 1:length(intervention)

% Assign 's'  struct
s = organizedData.(folderName).processed.(intervention{x}).processedGait;
fields = fieldnames(s);

for i = 1:numel(fields)
    if contains(fields{i}, 'POST_FV')
        s = renameStructField(s, fields{i}, 'postFV');
    elseif contains(fields{i}, 'POST_SSV')
        s = renameStructField(s, fields{i}, 'postSSV');
    elseif contains(fields{i}, 'PRE_FV')
        s = renameStructField(s, fields{i}, 'preFV');
    elseif contains(fields{i}, 'PRE_SSV')
        s = renameStructField(s, fields{i}, 'preSSV');
    end
end
organizedData.(folderName).processed.(intervention{x}).processedGait = s;

end

for x = 1:length(intervention)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(intervention{x}).filteredEMG;
    fields = fieldnames(s);
    newStruct = struct();

    for i = 1:numel(fields)
        trialNum = extractBetween(fields{i}, 'V', '_mat'); % Extract trial number
        if contains(fields{i}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{i});
        end
    end
    organizedData.(folderName).processed.(intervention{x}).filteredEMG = newStruct;
end

for x = 1:length(intervention)
    % Assign 's'  struct
    s = organizedData.(folderName).processed.(intervention{x}).loadedXSENS;
    fields = fieldnames(s);
    newStruct = struct();

    for i = 1:numel(fields)
        trialNum = extractBetween(fields{i}, 'V_00', '_xlsx'); % Extract trial number
        if contains(fields{i}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{i});
        elseif contains(fields{i}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{i});
        end
    end
    organizedData.(folderName).processed.(intervention{x}).loadedXSENS = newStruct;
end


%%
% Define muscles and joints
muscles = {'HAM', 'RF', 'MG', 'TA', 'VL'};
joints = {'H', 'K', 'A'};

% Initialize column names for the results table
columnNames = {'SubjectID','StimNoStim', 'Intensity','Frequency','Velocity','Pre/Post', 'Trial', 'GaitCycle', 'StepLenSym', 'SwingTimeSym', 'StrideVelocitySym','Synergies Needed'};
for m = muscles
    columnNames = [columnNames, strcat(m, '_rmsSymmetry'), strcat(m, '_aucSymmetry'), ...
                   strcat(m, '_maxCorr'), strcat(m, '_peakLag')];
end
for j = joints
    columnNames = [columnNames, strcat(j, '_rmsSymmetry'), strcat(j, '_aucSymmetry'), ...
                   strcat(j, '_maxCorr'), strcat(j, '_peakLag'), strcat(j, '_romSymmetry')];
end

if ~ isfile(csvFileName)
% Initialize the results table
resultsTable = table('Size', [0, numel(columnNames)], 'VariableTypes', repmat({'double'}, 1, numel(columnNames)), 'VariableNames', columnNames);
end
% Main processing loop
for x = 1:length(intervention)
    SubjectID = folderName;
    Intervention = intervention{x};

    % Initialize variables
    intensity = '';
    frequency = NaN;
    
    % Determine intensity based on intervention name
    if contains(Intervention, 'RMT')
        intensity = 'RMT';
    elseif contains(Intervention, 'TOL')
        intensity = 'TOL';
    elseif contains(Intervention, 'SHAM')
        intensity = 'SHAM';
    end
    
    % Determine frequency based on intervention name and intensity
    if contains(Intervention, '30')
        frequency = 30;
    elseif contains(Intervention, '50')
        frequency = 50;
    end
    
    % Set frequency to 0 if intensity is 'SHAM'
    if strcmp(intensity, 'SHAM')
        frequency = 0;
    end

    % Determine Stim/NoStim based on the presence of 'SHAM'
    if contains(Intervention, 'SHAM')
        StimNoStim = 'NoStim';
    else
        StimNoStim = 'Stim';
    end

    emg = organizedData.(SubjectID).processed.(Intervention).filteredEMG;
    gait = organizedData.(SubjectID).processed.(Intervention).processedGait;
    xsens = organizedData.(SubjectID).processed.(Intervention).loadedXSENS;

    f = fieldnames(emg);
    for j = 1:length(f)
        task = f{j};

        % Initialize variables
        velocity = '';
        pre_post = '';
        
        % Determine velocity based on task name
        if contains(task, 'SSV')
            velocity = 'SSV';
        elseif contains(task, 'FV')
            velocity = 'FV';
        end
        
        % Determine pre_post based on task name
        if contains(task, 'pre')
            pre_post = 'pre';
        elseif contains(task, 'post')
            pre_post = 'post';
        end
        
        accumulatedEMG = downSampleEMG_Cycle(emg.(task), gait.(task));
        accumulatedJointAngles = downSampleXSENS_Cycle(xsens.(task), gait.(task));

        trials = fieldnames(accumulatedEMG);
        for t = 1:length(trials)
            emgTrial = accumulatedEMG.(trials{t});
            xsensTrial = accumulatedJointAngles.(trials{t});
            gaitTrial = gait.(task).(trials{t});

            Nleft = size(emgTrial.left.HAM, 1);
            Nright = size(emgTrial.right.HAM, 1);
            N = Nleft + Nright - 1; % Total number of overlapping gait cycles

            leadingFoot = emgTrial.leadingFoot;  % This assumes leadingFoot is correctly provided in your dataset

            for c = 1:N
                if strcmp(leadingFoot, 'right')
                    if mod(c, 2) == 1  % Odd cycles (right leading)
                        rightIdx = ceil(c / 2);
                        leftIdx = rightIdx;  % Match left idx to right idx
                    else  % Even cycles
                        leftIdx = ceil(c / 2);
                        rightIdx = leftIdx + 1;  % Right idx one step ahead of left
                    end
                else
                    if mod(c, 2) == 1  % Odd cycles (left leading)
                        leftIdx = ceil(c / 2);
                        rightIdx = leftIdx;  % Match right idx to left idx
                    else  % Even cycle
                        rightIdx = ceil(c / 2);
                        leftIdx = rightIdx + 1;  % Stay within bounds
                    end
                end
                % Check boundaries to ensure indices are within the valid range
                if rightIdx > Nright || leftIdx > Nleft
                    continue; % Skip cycles where indices exceed available data
                end

                newRow = {SubjectID, StimNoStim, intensity, frequency, velocity, pre_post, t, c, gaitTrial.StepLenSym(c+1), gaitTrial.SwingTimeSym(c), gaitTrial.StrideVelocitySym(c)};

                % Muscle data for synergy calculation
                leftMuscles = [emgTrial.left.HAM(leftIdx, :); emgTrial.left.RF(leftIdx, :); emgTrial.left.MG(leftIdx, :); emgTrial.left.TA(leftIdx, :); emgTrial.left.VL(leftIdx, :)];
                rightMuscles = [emgTrial.right.HAM(rightIdx, :); emgTrial.right.RF(rightIdx, :); emgTrial.right.MG(rightIdx, :); emgTrial.right.TA(rightIdx, :); emgTrial.right.VL(rightIdx, :)];
                
                nSynergiesRequired = calculateSynergies_Cycle(leftMuscles, rightMuscles);
                newRow = [newRow, nSynergiesRequired];

                % Append metrics for muscles
                for m = muscles
                    leftEMG = emgTrial.left.(m{1})(leftIdx, :);
                    rightEMG = emgTrial.right.(m{1})(rightIdx, :);

                    [corrValues, lags] = xcorr(leftEMG, rightEMG, 'coeff');
                    [maxCorr, maxIdx] = max(corrValues);
                    peakLag = lags(maxIdx);

                    rmsLeft = rms(leftEMG);
                    rmsRight = rms(rightEMG);
                    aucLeft = trapz(leftEMG);
                    aucRight = trapz(rightEMG);

                    rmsSymmetry = (2 * abs(rmsLeft - rmsRight)) / (rmsLeft + rmsRight);
                    aucSymmetry = (2 * abs(aucLeft - aucRight)) / (aucLeft + aucRight);

                    newRow = [newRow, rmsSymmetry, aucSymmetry, maxCorr, peakLag];
                end

                for j = joints
                    leftJoint = xsensTrial.left.(j{1})(leftIdx, :);
                    rightJoint = xsensTrial.right.(j{1})(rightIdx, :);

                    [corrValues, lags] = xcorr(leftJoint, rightJoint, 'coeff');
                    [maxCorr, maxIdx] = max(corrValues);
                    peakLag = lags(maxIdx);

                    rmsLeft = rms(leftJoint);
                    rmsRight = rms(rightJoint);
                    aucLeft = trapz(leftJoint);
                    aucRight = trapz(rightJoint);

                    romLeft = max(leftJoint) - min(leftJoint);
                    romRight = max(rightJoint) - min(rightJoint);

                    rmsSymmetry = (2 * abs(rmsLeft - rmsRight)) / (rmsLeft + rmsRight);
                    aucSymmetry = (2 * abs(aucLeft - aucRight)) / (aucLeft + aucRight);
                    romSymmetry = (2 * abs(romLeft - romRight)) / (romLeft + romRight);

                    newRow = [newRow, rmsSymmetry, aucSymmetry, maxCorr, peakLag, romSymmetry];
                end

                % Convert the row to a table and append it to the results table
                newRowTable = cell2table(newRow, 'VariableNames', columnNames);
                resultsTable = [resultsTable; newRowTable];
            end
        end
    end
end

% Define the output filename
outputFileName = 'MLresults.csv';  % or 'processed_results.mat'

% Save to CSV
writetable(resultsTable, outputFileName);





