function [missingFiles] = identifyMissingDataPaths(config)
%% PURPOSE: LIST ALL OF THE FILES THAT ARE MISSING FROM THE RTO THAT SHOULD BE THERE.
% Inputs:
% config: Configuration struct.
%
% Config fields:
% BASE_PATH: The folder where all of the data is stored
% SUBJECT_LIST: The cell array of all subject folder names
% DATA_TYPES_LIST: A cell array of the folder names for the data types
% INTERVENTION_LIST: A cell array of the folder names for the interventions
% PRE_POST: Cell array with the value {'PRE', 'POST'}
% SPEED_LIST:
% SINGLE_FILE_TYPES: Cell array listing which data types have just one
% file per combination.
% NUM_REPEAT_FILES: Scalar numeric indicating how many repeat files there
% are per combination of the above.
% EXTENSIONS: Struct of cell arrays listing the file extensions. Each key is
% a data type.

% Create indices for all possible combinations
dims = {
    1:length(config.SUBJECT_LIST)
    1:length(config.DATA_TYPES_LIST)
    1:length(config.INTERVENTION_LIST)
    1:length(config.PRE_POST)
    };

% Generate all combinations using MATLAB's built-in cartesian product function
[s, d, i, p] = ndgrid(dims{:});

% Create a table with all combinations
combinations = table(...
    config.SUBJECT_LIST(s(:)), ...
    config.DATA_TYPES_LIST(d(:)), ...
    config.INTERVENTION_LIST(i(:)), ...
    config.PRE_POST(p(:)), ...
    'VariableNames', {'Subject', 'DataType', 'Intervention', 'PrePost'});

% Add column for base filepath
combinations.BasePath = fullfile(config.BASE_PATH, ...
    combinations.Subject, ...
    combinations.DataType, ...
    combinations.Intervention);

% Add column for base filename
combinations.BaseFilename = strcat(...
    combinations.Subject, '_', ...
    combinations.Intervention, '_', ...
    combinations.PrePost);

% Initialize output cell array
missingFiles = {};
singleFileTypes = config.SINGLE_FILE_TYPES;
numFiles = config.NUM_REPEAT_FILES;
speeds = config.SPEEDS_LIST;
repeat_prefixes = config.REPEAT_PREFIX;
dataType_insert = config.DATATYPE_INSERT;

% Process each row of the combinations table
for idx = 1:height(combinations)
    row = combinations(idx,:);
    extensions = config.EXTENSIONS.(row.DataType{1});
    hasSpeed = ~ismember(row.DataType{1}, config.DATATYPES_WITHOUT_SPEED);
    if isfield(repeat_prefixes, row.DataType{1})
        repeat_prefix = repeat_prefixes.(row.DataType{1});
    else
        repeat_prefix = '';
    end

    if isfield(dataType_insert, row.DataType{1})
        baseTemplateStr = ['%s_' dataType_insert.(row.DataType{1}) '_%s_%s'];
    else
        baseTemplateStr = '%s_%s_%s';
    end

    if hasSpeed
        numSpeeds = length(speeds);
    else
        numSpeeds = 1;
    end

    for speedNum = 1:numSpeeds

        if hasSpeed
            baseFilename = sprintf([baseTemplateStr '_%s'], ...
                row.Subject{1}, ...
                row.Intervention{1}, ...
                row.PrePost{1}, ...
                speeds{speedNum});
        else
            baseFilename = sprintf(baseTemplateStr, ...
                row.Subject{1}, ...
                row.Intervention{1}, ...
                row.PrePost{1});
        end

        for extNum = 1:length(extensions)
            ext = extensions{extNum};
            if ~ismember(row.DataType{1}, singleFileTypes)
                % Check for files 1,2,3
                for fileNum = 1:numFiles
                    filename = [baseFilename, repeat_prefix, num2str(fileNum), ext];
                    fullPath = fullfile(row.BasePath{1}, filename);
        
                    if ~isfile(fullPath)
                        missingFiles{end+1,1} = fullPath;
                    end
                end
            else
                % Check for single file
                filename = [baseFilename, ext];
                fullPath = fullfile(row.BasePath{1}, filename);
        
                if ~isfile(fullPath)
                    missingFiles{end+1,1} = fullPath;
                end
            end
        end
    end
end

% Display summary
if isempty(missingFiles)
    fprintf('All expected files were found.\n');
else
    fprintf('Found %d missing files:\n', length(missingFiles));
    for i = 1:length(missingFiles)
        fprintf('%s\n', missingFiles{i});
    end
end