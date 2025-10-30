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

% 2. For each file:
% - Load the file
% - Plot each muscle individually (with comments as vertical lines)
% - Plot all muscles together on the same plot (with comments as vertical
% lines)
% - Save the plots to a subfolder at the same location

fileOfInt = 'PulltoStand'; % TESTING ONLY

folders = config.FOLDERS;
for folderNum = 1:length(folders)
    folder = folders{folderNum};
    fileList = dir(folder);
    for fileNum = 1:length(fileList)
        fileRow = fileList(fileNum);
        if ~endsWith(fileRow.name, '.mat')
            continue; % Ignore the non-.mat files.
        end
        % TESTING ONLY
        if ~contains(fileRow.name, fileOfInt)
            continue;
        end
        isIgnored = false;
        for ignoreFileNum = 1:length(config.IGNORE_FILES)
            ignoreFileName = config.IGNORE_FILES{ignoreFileNum};
            if contains(fileRow.name, ignoreFileName)
                isIgnored = true;
            end
        end
        if isIgnored
            continue;
        end
        % Skip files if not explicitly included
        if ~isempty(config.INCLUDE_FILES) && ~ismember(fileRow.name, config.INCLUDE_FILES)
            continue;
        end
        filePath = fullfile(fileRow.folder, fileRow.name);
        % Prep to save the figures
        saveFolderPath = fullfile(fileRow.folder, 'Plots');
        mkdir(saveFolderPath);
        titleStr = strrep(fileRow.name, '.mat', ''); % Remove the .mat suffix
        titleStr = strrep(titleStr, '_', ' '); % Remove underscores

        % Check if this figure needs processing
        saveFilePathFilteredFig = fullfile(saveFolderPath, [titleStr ' AllMusclesFiltered.fig']);
        if isfile(saveFilePathFilteredFig)
            answer = questdlg(saveFilePathFilteredFig, ...
                  'Re-run this file?', ...
                  'Yes', 'No', 'Cancel', ...
                  'Yes');
            if ~strcmp(answer, 'Yes')
                continue;
            end
        end        
        
        % Plot all the muscles with comments
        [figLoaded, figFiltered, loadedData, rawData, muscleNames] = processMMTFile(filePath, config.REMAPPING, config.FILTER, fs, config.RECTIFY, config.MOTION_MUSCLE_MAPPING, config.AESTHETICS);
        disp(filePath);
        disp(rawData.comtext);                     

        % Expand the ylabels to the full muscle names
        drawnow;
        pause(0.5);
        expandMuscleYLabels(figLoaded, config.MUSCLE_NAMES);
        expandMuscleYLabels(figFiltered, config.MUSCLE_NAMES);

        %% Manually specify where the muscles of interest are active
        handlesStruct = ginputMuscleActivity(figFiltered);
        musclesFigFiltered = copyIndividualSubplot(figFiltered, muscleNames);
        ginputMuscleActivity(figLoaded, handlesStruct);
        musclesFigLoaded = copyIndividualSubplot(figLoaded, muscleNames);

        setAesthetics(figFiltered, config.AESTHETICS);
        setAesthetics(figLoaded, config.AESTHETICS);

        % Save the loaded data figure
        figLoaded.WindowState = 'maximized';
        sgtitle(figLoaded, titleStr,'Interpreter','None');
        saveFilePath = fullfile(saveFolderPath, [titleStr ' AllMusclesRaw']);
        saveas(figLoaded, [saveFilePath '.fig']);
        saveas(figLoaded, [saveFilePath '.png']);

        % Save the filtered figure
        figFiltered.WindowState = 'maximized';
        sgtitle(figFiltered, titleStr,'Interpreter','None');
        saveFilePath = fullfile(saveFolderPath, [titleStr ' AllMusclesFiltered']);
        saveas(figFiltered, [saveFilePath '.fig']);
        saveas(figFiltered, [saveFilePath '.png']);

        if ~config.DO_MANUAL
            close(figLoaded);
            close(figFiltered);
            continue;
        end

        %% Manually specify where the muscles of interest are active
        handlesStruct = ginputMuscleActivity(figFiltered);
        musclesFigFiltered = copyIndividualSubplot(figFiltered, muscleNames);
        ginputMuscleActivity(figLoaded, handlesStruct);
        musclesFigLoaded = copyIndividualSubplot(figLoaded, muscleNames);

        % Save the specific muscles' figures
        if musclesFigLoaded ~= false
            setAesthetics(musclesFigLoaded, config.AESTHETICS);
            allAx = findobj(musclesFigLoaded, 'Type', 'Axes');
            highestAx = allAx(1);
            for axNum = 1:length(allAx)
                ax = allAx(axNum);
                if ax.Position(2) > highestAx.Position(2)
                    highestAx = ax;
                end
            end
            highestAx.PositionConstraint = 'innerposition';
            title(highestAx, titleStr, 'Interpreter','None', 'FontSize', config.AESTHETICS.LABEL_FONT_SIZE, 'FontWeight', 'normal');             
            saveFilePath = fullfile(saveFolderPath, [titleStr ' ' musclesFigLoaded.Name ' Loaded']);
            saveas(musclesFigLoaded, [saveFilePath '.fig']);
            saveas(musclesFigLoaded, [saveFilePath '.png']);
            close(musclesFigLoaded);
        end
        if musclesFigFiltered ~= false
            setAesthetics(musclesFigFiltered, config.AESTHETICS);
            allAx = findobj(musclesFigFiltered, 'Type', 'Axes');
            highestAx = allAx(1);
            for axNum = 1:length(allAx)
                ax = allAx(axNum);
                if ax.Position(2) > highestAx.Position(2)
                    highestAx = ax;
                end
            end
            highestAx.PositionConstraint = 'innerposition';
            title(highestAx, titleStr, 'Interpreter','None', 'FontSize', config.AESTHETICS.LABEL_FONT_SIZE, 'FontWeight', 'normal');             
            saveFilePath = fullfile(saveFolderPath, [titleStr ' ' musclesFigFiltered.Name ' Filtered']);
            saveas(musclesFigFiltered, [saveFilePath '.fig']);
            saveas(musclesFigFiltered, [saveFilePath '.png']);
            close(musclesFigFiltered);
        end
        close(figLoaded);
        close(figFiltered);
    end
end