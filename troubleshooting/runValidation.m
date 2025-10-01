addpath(genpath("Y:\LabMembers\MTillman\MATLAB_FileExchange_Repository"));

config_path = "Y:\LabMembers\MTillman\GitRepos\Stroke-R01-Aim-2\troubleshooting\config.toml";
config = toml.map_to_struct(toml.read(config_path));

currDate = char(datetime('now'));
saveFilePath = ['missing_files_' currDate(1:11) '.csv'];
validationResults = validate_study_data(config, saveFilePath);