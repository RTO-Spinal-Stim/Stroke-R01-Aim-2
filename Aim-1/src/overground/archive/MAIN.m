% MT 01/14/25: Editing to make work with config file, and adding lots of comments.

clearvars
clc
addpath(genpath('Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Ameen_EMG_kinematics'));
% Path to save the data to.
subjectSavePath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\Processed Outcomes\SS13_Outcomes.mat';
% Folder to load the data from.
subjectLoadPath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\SS13';

% Extract folder name from the path
[~, subjFolderName, ~] = fileparts(subjectLoadPath);

% Create a struct with dynamic field names
folderStruct = struct();

% Assign an empty struct to the dynamic field
folderStruct.(subjFolderName) = struct();

%% Get configuration
config = jsondecode(fileread('config.json'));

% One subfolder per data type
dataTypeFolders = {'Delsys','Gaitrite','XSENS'};

% One subfolder per intervention. Note that intervention folder names are
% not valid MATLAB names, hence the need for a mapping.
interventionFolders = config.INTERVENTION_FOLDERS;
interventionFoldersMap = containers.Map(interventionFolders, ...
    config.MAPPED_INTERVENTION_FIELDS);

% Define the file extensions for each subfolder type
fileExtensions = {'*.mat','*.xlsx','*.xlsx'};

%% Load all of the data for one subject and place it in a nested struct.
% FORMAT: folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder).(fieldName)
for i = 1:length(interventionFolders)
    interventionFolder = interventionFolders{i};
    % Use the mapping to get the correct struct field name
    interventionStructName = interventionFoldersMap(interventionFolder);
    
    % Initialize sub-struct for the intervention folder
    folderStruct.(subjFolderName).(interventionStructName) = struct();
    
    % Iterate over dataTypeFolders
    for j = 1:length(dataTypeFolders)
        dataTypeFolder = dataTypeFolders{j};
        
        % Initialize a struct for each dataTypeFolder
        folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder) = struct();
        
        % Construct the path to the files
        filesPath = fullfile(subjectLoadPath, dataTypeFolder, interventionFolder, fileExtensions{j});
        files = dir(filesPath);
        
        % Load the data based on file type
        for k = 1:length(files)
            if isempty(files(k).name)
                continue;
            end
            fileName = files(k).name;
            fullFilePath = fullfile(files(k).folder, fileName); % The full path of the file being loaded.
            fieldName = matlab.lang.makeValidName(files(k).name);            
            
            disp(['Now loading: ' fullFilePath]);
            
            % Load .mat files for 'Delsys'
            if strcmp(dataTypeFolder, 'Delsys')
                data = load(fullFilePath);                
            % Load .xlsx files for 'Gaitrite'
            elseif strcmp(dataTypeFolder, 'Gaitrite')
                [num, txt, raw_data] = xlsread(fullFilePath);
            % Load .xlsx files for 'Gaitrite'
            elseif strcmp(dataTypeFolder, 'XSENS')
                [num, txt, raw_data] = xlsread(fullFilePath, 'Joint Angles XZY');
            end
            
            % Store data to struct
            if any(strcmp(dataTypeFolder, {'Gaitrite', 'XSENS'}))                
                % Store the data in a struct with the file name as the field
                folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder).(fieldName).num = num;
                folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder).(fieldName).txt = txt;
                folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder).(fieldName).raw = raw_data;
            elseif strcmp(dataTypeFolder, 'Delsys')
                % Store the data in a struct with the file name as the field                
                folderStruct.(subjFolderName).(interventionStructName).(dataTypeFolder).(fieldName) = data;
            end                
        end
    end
end

%% Extract EMG data into separate muscles
disp(['Extracting EMG data']);
interventions = fieldnames(folderStruct.(subjFolderName));
for i = 1:length(interventions)
    EMGStruct = folderStruct.(subjFolderName).(interventions{i}).Delsys;
    folderStruct.(subjFolderName).(interventions{i}).loadedDelsys = loadMatFiles(EMGStruct);    
end

%% Extract .num field of Gaitrite data
disp(['Extracting Gaitrite data']);
for i = 1:length(interventions)
    GaitStruct = folderStruct.(subjFolderName).(interventions{i}).Gaitrite;
    folderStruct.(subjFolderName).(interventions{i}).loadedGaitrite = loadExcelFiles(GaitStruct);
    
end

%% Extract .num field of XSENS data
disp(['Extracting XSENS data']);
for i = 1:length(interventions)
    XsensStruct = folderStruct.(subjFolderName).(interventions{i}).XSENS;
    folderStruct.(subjFolderName).(interventions{i}).loadedXSENS = loadExcelFiles(XsensStruct);
end

%% Fix muscle mappings for specific subject & interventions.
disp('Fixing muscle mappings for specific subjects & interventions');
validCombinations.SS08 = 'RMT30';
validCombinations.SS09 = 'SHAM2';
validCombinations.SS10 = {'SHAM2','RMT30','RMT50'};
% validCombinations = config.VALID_COMBINATIONS; % Define valid subjFolderName and intervention mappings
for i = 1:length(interventions)
    intervention = interventions{i};
    
    if isfield(validCombinations, subjFolderName) && ...
            any(strcmp(intervention, validCombinations.(subjFolderName)))
        % Log original and updated values for validation
        disp(['Processing: ', subjFolderName, ' -> ', intervention]);
        
        % Apply muscle correction for the valid combination
        fixMuscleMappings(folderStruct, subjFolderName, intervention);
        
        % Display the updated fields for validation
        disp('Updated fields:');
        disp(folderStruct.(subjFolderName).(intervention).loadedDelsys);
    end
    
end


%% Pre-Process Data
configFilterEMG = config.DELSYS_EMG.FILTER; % Get the EMG filtering configuration
EMG_Fs = config.DELSYS_EMG.SAMPLING_FREQUENCY; %Delsys sampling freq
GAIT_Fs = config.GAITRITE.SAMPLING_FREQUENCY;
X_Fs = config.XSENS.SAMPLING_FREQUENCY;

%Pre-Process EMG Data
disp('Preprocessing EMG data');
for i = 1:length(interventions)
    EMGStruct = folderStruct.(subjFolderName).(interventions{i}).loadedDelsys;    
    folderStruct.(subjFolderName).(interventions{i}).filteredEMG = preprocessEMG(EMGStruct, configFilterEMG, EMG_Fs);
end

%Process GAITRite Data
disp('Preprocessing GaitRite data');
for i = 1:length(interventions)
    gaitStruct = folderStruct.(subjFolderName).(interventions{i}).loadedGaitrite;    
    folderStruct.(subjFolderName).(interventions{i}).processedGait = processGAITRite(gaitStruct,GAIT_Fs, EMG_Fs, X_Fs);
end

%% Put the data in the "organizedData" struct.
disp('Copying loaded data to organizedData struct');
for i = 1:length(interventions)
    
    intervention = interventions{i};
    organizedData.(subjFolderName).raw.(intervention).Delsys  = folderStruct.(subjFolderName).(intervention).Delsys;
    organizedData.(subjFolderName).raw.(intervention).Gaitrite  = folderStruct.(subjFolderName).(intervention).Gaitrite;
    organizedData.(subjFolderName).raw.(intervention).XSENS  = folderStruct.(subjFolderName).(intervention).XSENS;
    
    organizedData.(subjFolderName).processed.(intervention).loadedDelsys  = folderStruct.(subjFolderName).(intervention).loadedDelsys;
    organizedData.(subjFolderName).processed.(intervention).loadedGaitrite  = folderStruct.(subjFolderName).(intervention).loadedGaitrite;
    organizedData.(subjFolderName).processed.(intervention).loadedXSENS  = folderStruct.(subjFolderName).(intervention).loadedXSENS;
    organizedData.(subjFolderName).processed.(intervention).filteredEMG  = folderStruct.(subjFolderName).(intervention).filteredEMG;
    organizedData.(subjFolderName).processed.(intervention).processedGait  = folderStruct.(subjFolderName).(intervention).processedGait;
    
end

%% Rename GaitRite struct fields to remove redundant info
disp('Removing redundancies from GaitRite struct field names');
for i = 1:length(interventions)
    
    % Assign 's'  struct
    s = organizedData.(subjFolderName).processed.(interventions{i}).processedGait;
    fields = fieldnames(s);
    
    for j = 1:numel(fields)
        if contains(fields{j}, 'POST_FV')
            s = renameStructField(s, fields{j}, 'postFV');
        elseif contains(fields{j}, 'POST_SSV')
            s = renameStructField(s, fields{j}, 'postSSV');
        elseif contains(fields{j}, 'PRE_FV')
            s = renameStructField(s, fields{j}, 'preFV');
        elseif contains(fields{j}, 'PRE_SSV')
            s = renameStructField(s, fields{j}, 'preSSV');
        end
    end
    organizedData.(subjFolderName).processed.(interventions{i}).processedGait = s;
    
end

%% Rename EMG struct fields
disp('Removing redundancies from EMG struct field names');
for i = 1:length(interventions)
    % Assign 's'  struct
    s = organizedData.(subjFolderName).processed.(interventions{i}).filteredEMG;
    fields = fieldnames(s);
    newStruct = struct();
    
    for j = 1:numel(fields)
        trialNum = extractBetween(fields{j}, 'V', '_mat'); % Extract trial number
        if contains(fields{j}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{j});
        end
    end
    organizedData.(subjFolderName).processed.(interventions{i}).filteredEMG = newStruct;
end

%% Rename XSENS struct fields
disp('Removing redundancies from XSENS struct field names');
for i = 1:length(interventions)
    % Assign 's'  struct
    s = organizedData.(subjFolderName).processed.(interventions{i}).loadedXSENS;
    fields = fieldnames(s);
    newStruct = struct();
    
    for j = 1:numel(fields)
        trialNum = extractBetween(fields{j}, 'V_00', '_xlsx'); % Extract trial number
        if contains(fields{j}, 'POST_FV')
            newStruct.postFV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'POST_SSV')
            newStruct.postSSV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'PRE_FV')
            newStruct.preFV.(['trial' trialNum{1}]) = s.(fields{j});
        elseif contains(fields{j}, 'PRE_SSV')
            newStruct.preSSV.(['trial' trialNum{1}]) = s.(fields{j});
        end
    end
    organizedData.(subjFolderName).processed.(interventions{i}).loadedXSENS = newStruct;
end

%% Downsample EMG & XSENS
disp('Downsampling EMG and XSENS to GaitRite frequencies');
muscle_names = {'HAM','RF','MG','TA','VL'};
joint_names = {'H','K','A'};
filterJointsConfig = struct('LOWPASS_CUTOFF', 6, 'LOWPASS_ORDER', 4);
for i = 1:length(interventions)
    
    intervention = interventions{i};
    emg = organizedData.(subjFolderName).processed.(intervention).filteredEMG;
    gait = organizedData.(subjFolderName).processed.(intervention).processedGait;
    xsens = organizedData.(subjFolderName).processed.(intervention).loadedXSENS;
    
    f = fieldnames(emg);
    
    for j = 1:length(f)
        
        %Average EMG for all gait cycles and trials
        [averagedEMG, accumulatedEMG] = downSampleAveragedEMG(emg.(f{j}), gait.(f{j}), muscle_names);
        
        %Average XSens for all gait cycles and trials
        [accumulatedJointAngles, averagedXSENS]  = downSampleAveragedXSENS(xsens.(f{j}), gait.(f{j}), joint_names, filterJointsConfig, X_Fs);
        
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).averagedEMG = averagedEMG;
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).accumulatedEMG = accumulatedEMG;
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).accumulatedJointAngles = accumulatedJointAngles;
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).averagedXSENS = averagedXSENS;
        
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).stepLenSym = mean([gait.(f{j}).trial1.avgStepLenSym,gait.(f{j}).trial2.avgStepLenSym,gait.(f{j}).trial3.avgStepLenSym]);
        organizedData.(subjFolderName).processed.(intervention).combinedTrials.(f{j}).swingTimeSym = mean([gait.(f{j}).trial1.avgSwingTimeSym,gait.(f{j}).trial2.avgSwingTimeSym,gait.(f{j}).trial3.avgSwingTimeSym]);

    end

end

%% ---------------------- STARTING ANALYSIS ---------------------- 
%% Statistical Parametric Mapping (SPM) Analysis
addpath(genpath('spm1dmatlab-master'));
for i = 1:length(interventions)
    
    intervention = interventions{i};
    s = organizedData.(subjFolderName).processed.(intervention).combinedTrials;
    f = fieldnames(s);
    
    for j = 1:length(f)
        
        %Calculate Muslce Synergies
        avgSynergies = calculateSynergiesOld(s.(f{j}).accumulatedEMG);
        
        %SPM Analysis for both XSens and EMG
        X_SPM = SPM_Analysis(s.(f{j}).accumulatedJointAngles);
        EMG_SPM = SPM_Analysis(s.(f{j}).accumulatedEMG);
        
        %Calculate the differences between right and left side for both XSENS and EMG
        X_RLdifference = differenceInRLCalc(X_SPM, s.(f{j}).averagedXSENS);
        EMG_RLdifference = differenceInRLCalc(EMG_SPM, s.(f{j}).averagedEMG);
        
        organizedData.(subjFolderName).processed.(intervention).RLDiff.(f{j}).XSENS = X_RLdifference;
        organizedData.(subjFolderName).processed.(intervention).RLDiff.(f{j}).EMG = EMG_RLdifference;
        organizedData.(subjFolderName).processed.(intervention).synergies.(f{j}) = avgSynergies;
        
    end    
    
end

%%
outcomes = struct();
for i = 1:length(interventions)
    
    intervention = interventions{i};
    
    %XSENS DATA
    X_SenPostFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.XSENS;
    X_SenPreFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.XSENS;
    
    X_SenPostSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.XSENS;
    X_SenPreSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.XSENS;
    
    %EMG DATA
    emgPostFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.EMG;
    emgPreFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.EMG;
    
    emgPostSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.EMG;
    emgPreSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.EMG;
    
    %SYNERGY DATA
    synPostFV = organizedData.(subjFolderName).processed.(intervention).synergies.postFV;
    synPreFV = organizedData.(subjFolderName).processed.(intervention).synergies.preFV;
    
    synPostSSV = organizedData.(subjFolderName).processed.(intervention).synergies.postSSV;
    synPreSSV = organizedData.(subjFolderName).processed.(intervention).synergies.preSSV;
    
    %GAITRITE DATA
    %stepLen
    stepLenSymPostFV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.postFV.stepLenSym;
    stepLenSymPreFV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.preFV.stepLenSym;
    
    stepLenSymPostSSV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.postSSV.stepLenSym;
    stepLenSymPreSSV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.preSSV.stepLenSym;
    %swing time
    swingTimeSymPostFV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.postFV.swingTimeSym;
    swingTimeSymPreFV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.preFV.swingTimeSym;
    
    swingTimeSymPostSSV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.postSSV.swingTimeSym;
    swingTimeSymPreSSV = organizedData.(subjFolderName).processed.(intervention).combinedTrials.preSSV.swingTimeSym;
    
    muscles = fieldnames(organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.EMG.amplitude);
    joints = fieldnames(organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.XSENS.amplitude);
    
    for m = 1:length(muscles)
        
        postAmplitudeSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.EMG.amplitude.(muscles{m});
        preAmplitudeSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.EMG.amplitude.(muscles{m});
        postAmplitudeFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.EMG.amplitude.(muscles{m});
        preAmplitudeFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.EMG.amplitude.(muscles{m});
        
        postDurationSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.EMG.duration.(muscles{m});
        preDurationSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.EMG.duration.(muscles{m});
        postDurationFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.EMG.duration.(muscles{m});
        preDurationFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.EMG.duration.(muscles{m});        
        
        amplitudeDiffSSV = preAmplitudeSSV - postAmplitudeSSV;
        amplitudeDiffFV = preAmplitudeFV - postAmplitudeFV;
        durationDiffSSV = preDurationSSV - postDurationSSV;
        durationDiffFV = preDurationFV - postDurationFV;
        
        if isnan(amplitudeDiffSSV)            
            amplitudeDiffSSV = 0;            
        end
        
        if isnan(amplitudeDiffFV)            
            amplitudeDiffFV = 0;            
        end
        
        if isnan(durationDiffSSV)            
            durationDiffSSV = 0;            
        end
        
        if isnan(durationDiffFV)            
            durationDiffFV = 0;            
        end
        
        outcomes.(intervention).EMG.(muscles{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(intervention).EMG.(muscles{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(intervention).EMG.(muscles{m}).durationSSV = durationDiffSSV;
        outcomes.(intervention).EMG.(muscles{m}).durationFV = durationDiffFV;
        
    end    
    
    for m = 1:length(joints)
        
        postAmplitudeSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.XSENS.amplitude.(joints{m});
        preAmplitudeSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.XSENS.amplitude.(joints{m});
        postAmplitudeFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.XSENS.amplitude.(joints{m});
        preAmplitudeFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.XSENS.amplitude.(joints{m});
        
        postDurationSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postSSV.XSENS.duration.(joints{m});
        preDurationSSV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preSSV.XSENS.duration.(joints{m});
        postDurationFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.postFV.XSENS.duration.(joints{m});
        preDurationFV = organizedData.(subjFolderName).processed.(intervention).RLDiff.preFV.XSENS.duration.(joints{m});
        
        
        amplitudeDiffSSV = preAmplitudeSSV - postAmplitudeSSV;
        amplitudeDiffFV = preAmplitudeFV - postAmplitudeFV;
        durationDiffSSV = preDurationSSV - postDurationSSV;
        durationDiffFV = preDurationFV - postDurationFV;
        
        if isnan(amplitudeDiffSSV)            
            amplitudeDiffSSV = 0;            
        end
        
        if isnan(amplitudeDiffFV)            
            amplitudeDiffFV = 0;            
        end
        
        if isnan(durationDiffSSV)            
            durationDiffSSV = 0;            
        end
        
        if isnan(durationDiffFV)            
            durationDiffFV = 0;            
        end
        
        outcomes.(intervention).XSENS.(joints{m}).amplitudeSSV = amplitudeDiffSSV;
        outcomes.(intervention).XSENS.(joints{m}).amplitudeFV = amplitudeDiffFV;
        outcomes.(intervention).XSENS.(joints{m}).durationSSV = durationDiffSSV;
        outcomes.(intervention).XSENS.(joints{m}).durationFV = durationDiffFV;
        
    end
    
    
    outcomes.(intervention).synergies.FV = synPostFV - synPreFV;
    outcomes.(intervention).synergies.SSV = synPostSSV - synPreSSV;
    
    % Gaitrite Outcomes spatial/temporal
    
    outcomes.(intervention).stepLenSym.FV = ((stepLenSymPreFV - stepLenSymPostFV)/stepLenSymPreFV)*100;
    outcomes.(intervention).stepLenSym.SSV = ((stepLenSymPreSSV - stepLenSymPostSSV)/stepLenSymPreSSV)*100;
    
    outcomes.(intervention).swingTimeSym.FV = ((swingTimeSymPreFV - swingTimeSymPostFV)/swingTimeSymPreFV)*100;
    outcomes.(intervention).swingTimeSym.SSV = ((swingTimeSymPreSSV - swingTimeSymPostSSV)/swingTimeSymPreSSV)*100;
    
end

%% Save Outcomes for subject, specify subject
% save(subjectSavePath, 'outcomes');











