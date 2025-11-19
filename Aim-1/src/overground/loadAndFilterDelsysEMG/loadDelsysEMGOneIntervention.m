function [delsysData] = loadDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, intervention_field_name, regexsConfig, missingFilesPartsToCheck)

%% PURPOSE: LOAD ONE ENTIRE INTERVENTION OF DELSYS EMG DURING WALKING TRIALS
% Inputs:
% delsysConfig: Config struct for Delsys
% intervention_folder_path: The full path to the intervention folder
% intervention_field_name: The field name of the intervention
% regexsConfig: The config struct for the regexs
%
% Outputs:
% delsysData: The processed Delsys data table
%
% NOTE: Assumes that subject name, intervention name, pre/post, and speed (ssv/fv) are all present in the file name

file_extension = delsysConfig.FILE_EXTENSION;
subjects_interventions_to_fix = delsysConfig.SUBJECTS_INTERVENTIONS_TO_FIX;

% Get the mat files
generic_mat_path = fullfile(intervention_folder_path, file_extension);
mat_files = dir(generic_mat_path);
mat_file_names = {mat_files.name};

[~, idx] = sort(mat_file_names); % Ensure the trials are in order.
mat_files = mat_files(idx,:);
mat_file_names = {mat_files.name};

% Get the adicht files
generic_adicht_path = fullfile(intervention_folder_path, '*.adicht');
adicht_files = dir(generic_adicht_path);
adicht_file_names = {adicht_files.name};

[~,idx] = sort(adicht_file_names);
adicht_files = adicht_files(idx,:);
adicht_file_names = {adicht_files.name};


%% Rename/number struct fields and preprocess each file
delsysData = table;
priorNamesNoTrial = cell(length(mat_file_names), 1);
for i = 1:length(priorNamesNoTrial)
    priorNamesNoTrial{i} = ''; % Initialize as chars
end
columnNames = delsysConfig.CATEGORICAL_COLUMNS;
for i = 1:length(mat_file_names)
    mat_file_name_with_ext = mat_file_names{i};
    % Check if the file is missing
    isMissing = checkMissing(mat_file_name_with_ext, missingFilesPartsToCheck);
    if isMissing
        continue;
    end
    periodIndex = strfind(mat_file_name_with_ext, '.');
    mat_file_name = mat_file_name_with_ext(1:periodIndex-1);
    mat_file_path = fullfile(intervention_folder_path, mat_file_name_with_ext);    
    parsedName = parseFileName(regexsConfig, mat_file_name);
    subject_id = parsedName{1};
    speed = parsedName{3};
    nameNoTrial = [subject_id '_' intervention_field_name '_' speed];
    priorNamesNoTrial{i} = nameNoTrial;
    trialNum = sum(ismember(priorNamesNoTrial, {nameNoTrial}));
    nameWithTrial = [nameNoTrial '_trial' num2str(trialNum)];    
    loadedData = loadDelsysEMGOneFile(mat_file_path);

    %% Hard-coded fix for EMG muscle mappings for specific subjects & interventions
    if isfield(subjects_interventions_to_fix, subject_id) && ...
        any(strcmp(intervention_field_name, subjects_interventions_to_fix.(subject_id)))
        loadedData = fixMuscleMappings(loadedData);
    end
    
    tmpTable = table;
    for colNum = 1:length(parsedName)
        try
            tmpTable.(columnNames{colNum}) = string(parsedName{colNum});
            tmpTable.(columnNames{colNum}) = categorical(tmpTable.(columnNames{colNum}));
        catch e
            disp(['Error in file name part: ' columnNames{colNum}]);
            throw(e);
        end
    end
    adicht_idx = ismember(adicht_file_names, strrep(mat_file_name_with_ext, '.mat', '.adicht'));
    if any(adicht_idx)
        tmpTable.DateTimeSaved_Delsys = getDateSaved(adicht_files(adicht_idx).date);
    else
        tmpTable.DateTimeSaved_Delsys = NaT(1,'TimeZone','America/Chicago');
    end
    tmpTable.Delsys_Loaded = loadedData;   
    delsysData = [delsysData; tmpTable];
end

end

function [dateTimeSaved] = getDateSaved(fullDate)

%% PURPOSE: GET THE DATE AND TIME SAVED
% Inputs:
% fullDate: The full date for the current file from the dir()
%
% dateSaved: The datetime object

fullDate = char(fullDate);
spaceIdx = strfind(fullDate, ' ');
timeSaved = fullDate(spaceIdx(1)+1:end);            
% Missing AM or PM, so add it here.
colonIdx = strfind(timeSaved, ':');
hrNum = str2double(timeSaved(1:colonIdx(1)-1));
if hrNum >= 12                
    timeSaved = [timeSaved ' PM'];
    if hrNum >= 13
        hrNum = hrNum - 12;
        timeSaved = [num2str(hrNum) timeSaved(3:end)];
    end
else
    timeSaved = [timeSaved ' AM'];
end
dateTimeSaved = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'America/Chicago');
end