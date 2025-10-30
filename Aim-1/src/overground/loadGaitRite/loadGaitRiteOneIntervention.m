function [gaitRiteData] = loadGaitRiteOneIntervention(gaitRiteConfig, intervention_folder_path, intervention_field_name, regexsConfig, missingFilesPartsToCheck)

%% PURPOSE: LOAD ONE ENTIRE INTERVENTION OF GAITRITE DATA
% Inputs:
% gaitRiteConfig: Config struct
% intervention_folder_path: Path to the folder containing all files for this intervention
% intervention_field_name: The intervention name
% regexsConfig: The regexs to use to parse the file name.
%
% Outputs:
% gaitRiteData: The loaded GaitRite data

file_extension = gaitRiteConfig.FILE_EXTENSION;

generic_xlsx_path = fullfile(intervention_folder_path, file_extension);
xlsx_files = dir(generic_xlsx_path);
xlsx_file_names = {xlsx_files.name}';

%% Creating valid field names & pre-processing each file
% Output struct format:
% - trial
%     - stepLengthSymmetries
%     - swingTimeSymmetries
%     - AvgStepLenSym
%     - AvgSwingTimeSym
%     - seconds
%         - gaitEvents
%         - gaitPhases
%         - gaitPhasesDurations
%     - frames
%         - gaitEvents
%         - gaitPhases
%         - gaitPhasesDurations
gaitRiteData = table;
columnNames = gaitRiteConfig.CATEGORICAL_COLUMNS;
for i = 1:length(xlsx_file_names)    
    xlsx_file_name_with_ext = xlsx_file_names{i};
    if startsWith(xlsx_file_name_with_ext, '~$')
        continue; % Cache file, doesn't really exist.
    end
    period_index = strfind(xlsx_file_name_with_ext, '.');
    xlsx_file_name = xlsx_file_name_with_ext(1:period_index-1);
    xlsx_file_path = fullfile(intervention_folder_path, xlsx_file_name_with_ext);
    parsedName = parseFileName(regexsConfig, xlsx_file_name);    
    subject_id = parsedName{1};
    speed = parsedName{3};
    tableColName = [subject_id '_' intervention_field_name '_' speed];

    tmpTable = loadGaitRiteOneFile(xlsx_file_path, gaitRiteConfig); % Second output is for manual checking/validation
    for j = 1:height(tmpTable)
        % Add the categorical columns.
        for nameCount = 1:length(parsedName)
            if ~isempty(parsedName{nameCount})
                tmpTable.(columnNames{nameCount})(j) = string(parsedName{nameCount});
            end
        end
        tmpTable.(columnNames{length(parsedName)})(j) = num2str(j);     
    end    
    for colNum = 1:length(columnNames)
        tmpTable.(columnNames{colNum}) = categorical(string(tmpTable.(columnNames{colNum})));
    end
    gaitRiteData = addToTable(gaitRiteData, tmpTable);
end

% If the GaitRite data does not exist
if isempty(gaitRiteData)
    return;
end

% Put the categorical columns first
gaitRiteData = [gaitRiteData(:,columnNames), gaitRiteData(:,~ismember(gaitRiteData.Properties.VariableNames, columnNames))];