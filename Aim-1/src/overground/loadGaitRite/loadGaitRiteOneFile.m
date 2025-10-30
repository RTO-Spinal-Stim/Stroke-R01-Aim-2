function [GaitRiteTable] = loadGaitRiteOneFile(gaitRitePath, gaitRiteConfig)

%% PURPOSE: LOAD THE DATA FROM ONE GAITRITE FILE.
% Inputs:
% gaitRitePath: Full file path to one GaitRite file.
% gaitRiteConfig: Config struct for GaitRite
%
% Outputs:
% GaitRiteTable: The table of GaitRite data. One row per walk.

% Configuration
trialsColName = strtrim(gaitRiteConfig.COLUMN_NAMES.GAIT_ID);

[num_data, txt_data, cell_data] = xlsread(gaitRitePath);
header_row_num = find(contains(txt_data(:,1), 'ID'),1,'first');
header_row = txt_data(header_row_num,:);
for i = 1:length(header_row)
    header_row{i} = strtrim(header_row{i});
end
trialsColIdx = ismember(header_row, trialsColName);
timeColIdx = ismember(header_row, 'Time'); % For getting the DateTimeSaved

%% Separate each trial
unique_trials = unique(num_data(:, trialsColIdx), 'stable'); % Find the unique trial numbers

% 1. Loop through each unique trial number to separate and preprocess the data
GaitRiteTable = table;
for i = 1:length(unique_trials)
    trial_number = unique_trials(i);           
    trialData = num_data(num_data(:,trialsColIdx) == trial_number, :);
    tableOut = preprocessGaitRiteOneTrial(gaitRiteConfig, header_row, trialData);
    % Put the DateTimeSaved into tableOut column
    tableOut.DateTimeSaved_GaitRite = getDateTimeSaved(txt_data, num_data, timeColIdx, header_row_num, i);
    tableOut = [tableOut(:,end), tableOut(:,1:end-1)];
    GaitRiteTable = [GaitRiteTable; tableOut];
end

end

function [dateTimeSaved] = getDateTimeSaved(txt_data, num_data, timeColIdx, header_row_num, trialNum)

%% PURPOSE: GET THE DATE THAT A GIVEN TRIAL WAS SAVED
% Inputs:
% txt_data: The cell array of textual data from xlsread
% num_data: The numeric matrix of data
% timeColIdx: Logical vector indicating the Time column
% header_row_num: The header row in the txt_data
% trialNum: The trial number

trial_times = unique(txt_data(header_row_num+1:size(num_data,1)+header_row_num, timeColIdx), 'stable');
fullDate = trial_times{trialNum};
dateTimeSaved = datetime(fullDate, 'InputFormat', 'M/dd/yyyy h:mm:ss a', 'TimeZone', 'America/Chicago');
end