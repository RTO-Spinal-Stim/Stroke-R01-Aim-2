function [gaitRiteTable] = loadGaitRiteAllInterventions(gaitriteConfig, subject_gaitrite_folder, intervention_folders, mapped_interventions, regexsConfig, missingFilesPartsToCheck)

%% PURPOSE: LOAD THE GAITRITE DATA FOR ALL INTERVENTIONS.
% Inputs:
% gaitriteConfig: Config struct specifically for GaitRite
% subject_gaitrite_folder: The folder containing the subject's GaitRite data
% intervention_folders: Cell array of folder names, one per intervention
% mapped_interventions: The intervention folder names mapped to field names
% regexsConfig: Config struct for regexs
%
% Outputs:
% gaitRiteTable: Table with GaitRite data

disp('Loading GaitRite');

gaitRiteTable = table;
for i = 1:length(intervention_folders)
    intervention_folder = intervention_folders{i};    
    intervention_folder_path = fullfile(subject_gaitrite_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    % For loading Nicholas' data only
    % if ~isfolder(intervention_folder_path)
    %     continue;
    % end
    tmpTable = loadGaitRiteOneIntervention(gaitriteConfig, intervention_folder_path, intervention_field_name, regexsConfig, missingFilesPartsToCheck);
    % Missing GaitRite data. This happens if the session being analyzed hasn't occurred yet 
    % (OK for preliminary analysis of longitudinal data)
    if isempty(tmpTable)
        continue; 
    end
    gaitRiteTable = addToTable(gaitRiteTable, tmpTable);
end