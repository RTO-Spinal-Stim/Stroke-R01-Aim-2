function results = validate_study_data(config, saveFilePath)
% VALIDATE_STUDY_DATA Check if all expected data files exist
%   results = validate_study_data(config)
%
%   Input:
%       config - struct parsed from config.toml
%       saveFilePath - char of the full file path to save the missing files results to.
%   Output:
%       results - struct with validation results per subject

% Initialize results structure
results = struct();

numMissingRegex = 'Expected [0-9]';

% Loop through each subject
for subj_idx = 1:length(config.subjects)
    subj = config.subjects{subj_idx};
    subj_id = subj.id;
    last_session = subj.last_session;

    fprintf('\n=== Validating %s (last session: %s) ===\n', subj_id, last_session);

    % Find the index of last completed session
    last_session_idx = find(strcmp(config.session_order, last_session));

    % Get all sessions up to and including last completed
    completed_sessions = config.session_order(1:last_session_idx);

    % Initialize subject results
    results.(subj_id) = struct();
    results.(subj_id).total_missing = 0;
    results.(subj_id).sessions = struct();

    % Check each completed session
    for sess_idx = 1:length(completed_sessions)
        session = completed_sessions{sess_idx};

        % Determine expected data types for this session
        expected_types = get_expected_data_types(session, config);

        fprintf('\n  Session: %s\n', session);

        % Initialize session results
        results.(subj_id).sessions.(session) = struct();
        results.(subj_id).sessions.(session).missing_files = {};
        results.(subj_id).sessions.(session).found_files = {};

        % Check each expected data type
        for type_idx = 1:length(expected_types)
            data_type = expected_types{type_idx};

            % Find the data file specification for this type
            file_spec = get_file_spec(data_type, config.data_files);

            if isempty(file_spec)
                fprintf('    WARNING: No file specification for type: %s\n', data_type);
                continue;
            end

            % Check if files exist
            [missing, found] = check_files_exist(subj_id, session, file_spec, config.gr_trainings, config.root_path);
            
            if ~isempty(missing)                
                fprintf('    ❌ %s:\n', data_type);
                numMissingTotalForDataType = 0;
                for m = 1:length(missing)
                    numMissingStr = regexp(missing{m}, numMissingRegex,'match');
                    if ~isempty(numMissingStr)
                        numMissingStr = numMissingStr{1};
                        numMissing = regexp(numMissingStr, '\d+', 'match');
                        numMissing = str2double(strjoin(numMissing, ''));
                        numMissingTotalForDataType = numMissingTotalForDataType + numMissing;
                    else
                        % Missing all files
                        for j = 1:length(config.data_files)
                            if strcmp(config.data_files{j}.type, data_type)
                                numMissingTotalForDataType = config.data_files{j}.num_files_per_ext;
                                break;
                            end
                        end
                    end
                    fprintf('       - %s\n', missing{m});
                end
                results.(subj_id).sessions.(session).missing_files = ...
                    [results.(subj_id).sessions.(session).missing_files; missing];
                results.(subj_id).total_missing = results.(subj_id).total_missing + numMissingTotalForDataType;
            else
                fprintf('    ✓ %s: All files found (%d)\n', data_type, length(found));
            end

            results.(subj_id).sessions.(session).found_files = ...
                [results.(subj_id).sessions.(session).found_files; found'];
        end
    end
end

% Print overall summary
fprintf('\n\n=== OVERALL SUMMARY ===\n');
total_missing_all = 0;
for subj_idx = 1:length(config.subjects)
    subj_id = config.subjects{subj_idx}.id;
    fprintf('%s: %d missing files\n', subj_id, results.(subj_id).total_missing);
    total_missing_all = total_missing_all + results.(subj_id).total_missing;
end
fprintf('Total missing across all subjects: %d\n', total_missing_all);
write_to_file(saveFilePath, results);
end

function expected_types = get_expected_data_types(session, config)
% Determine which data types are expected for a given session

% Check if session has explicit expected types
if isfield(config.expected_data_types_per_session, session)
    expected_types = config.expected_data_types_per_session.(session);
    return;
end

% Check if it's a TX session
if startsWith(session, 'TX')
    % Check if it's a GR training session
    if any(strcmp(config.gr_trainings, session))
        expected_types = config.expected_data_types_per_session.TX_GR;
    else
        expected_types = config.expected_data_types_per_session.TX_NO_GR;
    end
    return;
end

% Default: no expected data
expected_types = {};
end

function file_spec = get_file_spec(data_type, data_files)
% Find the file specification for a given data type
file_spec = [];
for i = 1:length(data_files)
    if strcmp(data_files{i}.type, data_type)
        file_spec = data_files{i};
        return;
    end
end
end

function [missing, found] = check_files_exist(subj_id, session, file_spec, gr_trainings, root_path)
% Check if expected files exist for a subject/session
missing = {};
found = {};

% Replace {session} placeholder in pattern
pattern = strrep(file_spec.pattern, '{session}', session);

% Determine directory structure based on session type
if startsWith(session, 'TX') && ismember(session, gr_trainings)
    % TX sessions: root_path/SubjectID/Gaitrite/TX/Session
    search_dir = fullfile(root_path, subj_id, file_spec.type, 'TX', session);
else
    % Other sessions: root_path/SubjectID/Session
    search_dir = fullfile(root_path, subj_id, file_spec.type, session);
end

if ~exist(search_dir, 'dir')
    % If directory doesn't exist, all files are missing
    % Generate expected filenames based on pattern (simplified)
    missing = {sprintf('Directory not found: %s', search_dir)};
    return;
end

% Get all files in directory
all_files = dir(search_dir);
all_files = {all_files(~[all_files.isdir]).name};

% Extract all unique extensions from the pattern
% Pattern format: "...[ext1|ext2|ext3]"
ext_match = regexp(pattern, '\.\[([^\]]+)\]', 'tokens');
if ~isempty(ext_match)
    extensions = strsplit(ext_match{1}{1}, '|');
else
    % Single extension case: pattern ends with .ext
    ext_match = regexp(pattern, '\.([a-z0-9]+', 'tokens');
end
if ~isempty(ext_match)
    extensions = {ext_match{1}{1}};
else
    extensions = {};
end

% Check each extension separately
expected_count = file_spec.num_files_per_ext;

for ext_idx = 1:length(extensions)
    ext = extensions{ext_idx};

    % Create pattern for this specific extension
    pattern_for_ext = strrep(pattern, ['.[' strjoin(extensions, '|') ']'], ['.' ext]);

    % Match files for this extension
    matched_files = {};
    for i = 1:length(all_files)
        if ~isempty(regexp(all_files{i}, pattern_for_ext, 'once'))
            matched_files{end+1} = all_files{i};
            found{end+1} = fullfile(search_dir, all_files{i});
        end
    end

    actual_count = length(matched_files);

    if actual_count < expected_count
        missing{end+1} = sprintf('%s %s: Expected %d .%s files, found %d (pattern: "%s")', ...
            subj_id, file_spec.type, expected_count, ext, actual_count, pattern_for_ext);
    end
end
end

function write_to_file(filepath, results)

% Open CSV file for writing
fid = fopen(filepath, 'w');

% Write header
fprintf(fid, 'Subject_ID,Session,Missing_File\n');

% Get all subject IDs
subj_ids = fieldnames(results);

% Loop through each subject
for i = 1:length(subj_ids)
    subj_id = subj_ids{i};
    
    % Check if sessions field exists
    if isfield(results.(subj_id), 'sessions')
        % Get all session names
        sessions = fieldnames(results.(subj_id).sessions);
        
        % Loop through each session
        for j = 1:length(sessions)
            session = sessions{j};
            
            % Check if missing_files field exists
            if isfield(results.(subj_id).sessions.(session), 'missing_files')
                % Get the cell array of missing files
                missing_files = results.(subj_id).sessions.(session).missing_files;
                
                % Loop through each missing file
                for k = 1:length(missing_files)
                    % Write to CSV: subject_id, session, missing_file
                    fprintf(fid, '%s,%s,%s\n', subj_id, session, missing_files{k});
                end
            end
        end
    end
end

% Close the file
fclose(fid);

fprintf('Missing files exported to missing_files.csv\n');

end