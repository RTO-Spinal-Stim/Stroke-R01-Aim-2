function [loaded_data] = loadDelsysEMGOneFile(emgFilePath)

%% PURPOSE: LOAD THE DELSYS EMG DATA
% Inputs:
% emgFilePath: The full path to the EMG file
%
% Outputs:
% loaded_data: The loaded EMG data

%% Load the data, or use the data directly if the data struct is passed in.
if ischar(emgFilePath) || isstring(emgFilePath)
    from_file_data = load(emgFilePath);
else
    from_file_data = emgFilePath;
end

%% Parse each of the muscles from the 1xN vector of EMG data
% Extract muscle names from the loaded data
muscle_names = strrep(cellstr(from_file_data.titles), '''', '');
muscle_names = muscle_names(1:length(muscle_names)-1);

loaded_data = struct();
nan_idx = struct();

for i = 1:length(muscle_names)

    muscleName = muscle_names{i};
    startData = from_file_data.datastart(i);
    endData = from_file_data.dataend(i);

    if startData == -1
        continue;
    end

    loaded_data.(muscleName) = from_file_data.data(startData:endData);
    nan_idx.(muscleName) = isnan(loaded_data.(muscleName));

    % If all of the data are the same value, convert them to NaN
    if all(diff(loaded_data.(muscleName))==0)
        loaded_data.(muscleName) = NaN(size(loaded_data.(muscleName)));
    end

end

%% Check that NaN are found for all muscles.
ref_idx = nan_idx.(muscle_names{1});
is_consistent = true;
for i = 1:length(muscle_names)
    muscleName = muscle_names{i};
    if ~all(ref_idx == nan_idx.(muscleName))
        is_consistent = false;
        disp([muscleName ' has NaN at different indices than the other muscles!'])
    end
end
assert(is_consistent);

%% Remove NaN
for i = 1:length(muscle_names)
    muscleName = muscle_names{i};
    loaded_data.(muscleName)(nan_idx.(muscleName)) = [];
end