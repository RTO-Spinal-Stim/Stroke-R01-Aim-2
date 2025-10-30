%% PURPOSE: UPDATE THE TITLES OF THE PLOTS

% 1. Define MMT folder(s)
close all;
config_path = "Y:\LabMembers\MTillman\GitRepos\Stroke-R01\src\MMT\config_SY.json";
config = jsondecode(fileread(config_path));
paths_to_add = config.PATHS_TO_ADD;
for i = 1:length(paths_to_add)
    addpath(genpath(paths_to_add{i}));
end
fs = 2000;

if ~isfield(config, 'IGNORE_FILES')
    config.IGNORE_FILES = {};
end

if ~isfield(config, 'RECTIFY')
    config.RECTIFY = 0;
end

if ~isfield(config, 'REMAPPING')
    config.REMAPPING = struct();
end

if ~isfield(config, 'MOTION_MUSCLE_MAPPING')
    config.MOTION_MUSCLE_MAPPING = struct();
end

if ~isfield(config, 'DO_MANUAL')
    config.DO_MANUAL = true;
end

if ~isfield(config, 'INCLUDE_FILES')
    config.INCLUDE_FILES = {};
end

if ~isfield(config, 'MUSCLE_NAMES')
    config.MUSCLE_NAMES = struct();
end

config = init_aesthetics(config);

% The highest axes (muscle) for each movement.
m.LTA = 'Left Ankle Dorsiflexion';
m.LMG = 'Left Ankle Plantarflexion';
% m.LVL = 'Left Knee Extension';
m.LRF = 'Left Knee Extension';
m.LADD = {'Left Hip Flexion', 'Left Hip Adduction'};
m.LABD = 'Left Hip Abduction';
m.LHAM = {'Left Hip Extension', 'Left Knee Flexion'};
m.RTA = 'Right Ankle Dorsiflexion'; %
m.RMG = 'Right Ankle Plantarflexion'; %
% m.RVL = 'Right Knee Extension';
m.RRF = 'Right Knee Extension'; %
m.RADD = {'Right Hip Flexion', 'Right Hip Adduction'}; %
m.RABD = 'Right Hip Abduction'; %
m.RHAM = {'Right Hip Extension', 'Right Knee Flexion'}; %

m.LBRAD = 'Left Wrist Extension';
% m.LBI = 'Left Elbow Flexion';
% m.LTRI = 'Left Elbow Extension';
m.LED = 'Left Finger Extension';
m.LFDP = {'Left Wrist Flexion', 'Left Finger Flexion'};
m.LAPB = 'Left Thumb Opposition';
m.RBRAD = 'Right Wrist Extension'; %
% m.RBI = 'Right Elbow Flexion';
% m.RTRI = 'Right Elbow Extension';
m.RED = 'Right Finger Extension'; % 
% m.RFDP = 'Right Wrist Flexion'; %
m.RFDP = {'Right Wrist Flexion', 'Right Finger Flexion'}; %
m.RAPB = 'Right Thumb Opposition'; %

folders = config.FOLDERS;
for folderNum = 1:length(folders)
    folder = fullfile(folders{folderNum}, 'Plots');
    saveFolder = fullfile(folders{folderNum}, 'Plots Retitled');
    mkdir(saveFolder);
    fileList = dir(folder);
    for fileNum = 1:length(fileList)
        fileRow = fileList(fileNum);
        fileName = fileRow.name;
        if ~endsWith(fileName, '.fig')
            continue; % Ignore the non-.fig files.
        end

        filePath = fullfile(fileRow.folder, fileName);
        titleStr = strrep(fileName, '.fig', ''); % Remove the .fig suffix

        % Only modify the muscle of interest plots
        if ~contains(titleStr, ' Filtered')
            continue;
        end

        fileNameSplit = strsplit(fileName, ' ');
        fileNameStandard = [fileNameSplit{1} '_' fileNameSplit{2}];

        fig = openfig(filePath);
        drawnow;
        pause(0.2);
        allAx = findobj(fig, 'Type', 'Axes'); 
        ax = allAx(1);
        for i = 1:length(allAx)
            currAx = allAx(i);
            if currAx.Position(2) > ax.Position(2)
                ax = currAx;
            end
        end
        muscleName = ax.Tag;
        movementName = m.(muscleName);
        if iscell(movementName)
            close(fig);
            disp(['Multiple in: ' filePath]);
            continue;
        end
        saveFilePath = fullfile(saveFolder, fileName);
        if contains(saveFilePath, '7_24')
            prePostStr = 'PRE';
        elseif contains(saveFilePath, '7_30')
            prePostStr = 'POST';
        end
        ax.Title.String = [prePostStr ' - ' movementName];
        savefig(fig, saveFilePath);
        saveas(fig, strrep(saveFilePath, '.fig', '.png'));
        close(fig);

    end
end