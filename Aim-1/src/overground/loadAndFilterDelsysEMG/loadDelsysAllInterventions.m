function [delsysTable] = loadDelsysAllInterventions(delsysConfig, subject_delsys_folder, intervention_folders, mapped_interventions, regexsConfig, missingFilesPartsToCheck)

%% PURPOSE: LOAD AND PREPROCESS THE DELSYS DATA.
% Inputs:
% delsysConfig: Config struct for Delsys specifically
% subject_delsys_folder: The folder containing the subject's Delsys data
% intervention_folders: Cell array of folder names, one per intervention
% mapped_interventions: The intervention folder names mapped to field names
% regexsConfig: Config struct for regexs
%
% Outputs:
% delsysTable: Table with Delsys data

disp('Loading Delsys');

delsysTable = table;
for i = 1:length(intervention_folders)   
    intervention_folder = intervention_folders{i};        
    intervention_folder_path = fullfile(subject_delsys_folder, intervention_folder);
    intervention_field_name = mapped_interventions(intervention_folder);
    % if ~isfolder(intervention_folder_path)
    %     continue;
    % end
    tmpTable = loadDelsysEMGOneIntervention(delsysConfig, intervention_folder_path, intervention_field_name, regexsConfig, missingFilesPartsToCheck);
    if isempty(tmpTable)
        continue;
    end
    delsysTable = addToTable(delsysTable, tmpTable);
end