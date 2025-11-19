function [figLoaded, figFiltered, loadedData, rawLoadedData, muscleNames] = processMMTFile(filePath, remapping, filter_config, fs, rectify, motion_muscle_mapping, aesthetics_config)

%% PURPOSE: PROCESS ONE FILE'S MMT EMG
% Inputs:
% filePath: The path to the EMG file
% remapping: Struct of structs indicating which sensors in which files need
% to be remapped
% filter_config: Struct providing the filter configuration
% fs: EMG sampling rate
% rectify: 0 or 1 indicating whether or not to rectify the EMG data
% motion_muscle_mapping: Struct mapping MMT file names to the muscle(s) of interest
% aesthetics_config: Config struct for the aesthetics of the plot
%
% Outputs:
% figLoaded: Handle to the figure containing all muscles' raw data plots
% figFiltered: Handle to the figure containing all muscles' filtered data plots
% loadedData: The loaded EMG data
% rawLoadedData: The raw EMG data with comments
% muscleNames: The muscle name(s) for the current MMT file

%% Load data 
rawLoadedData = load(filePath);
loadedData = loadDelsysEMGOneFile(rawLoadedData);

%% Remap the EMG channels (if needed)
% If necessary, remap the EMG sensor names
remappingFiles = fieldnames(remapping);
for remapFileNum = 1:length(remappingFiles)
    remappingFile = remappingFiles{remapFileNum};
    if ~contains(filePath, remappingFile)
        continue;
    end
    sensorsToRemap = fieldnames(remapping.(remappingFile));
    for sensorNum = 1:length(sensorsToRemap)
        sensorNameToRemap = sensorsToRemap{sensorNum};
        remappedSensorName = remapping.(remappingFile).(sensorNameToRemap);
        loadedData.(remappedSensorName) = loadedData.(sensorNameToRemap);
        loadedData = rmfield(loadedData, sensorNameToRemap);
    end
end

%% Get the muscle names of interest
motionNames = fieldnames(motion_muscle_mapping);
motionName = false;
muscleNames = {};
for i = 1:length(motionNames)
    currMotionName = motionNames{i};
    if contains(filePath, currMotionName)
        motionName = currMotionName;
        break;
    end
end
if motionName
    muscleNames = motion_muscle_mapping.(motionName); % If a motion name from the config was found in an MMT file  path
end

%% Plot loaded EMG data and annotate the plots with comments
% Plot all muscles in subplots on the same figure.
figLoaded = figure();
figLoaded = plotOneTrialData(loadedData, figLoaded);
annotateFigure(figLoaded, rawLoadedData.com, rawLoadedData.comtext, muscleNames);
figLoaded.WindowState = 'maximized';
drawnow;
pause(0.5);
convertXToSec(figLoaded);

%% Filter the muscles' data
channels = fieldnames(loadedData);
filteredData = struct;
for channelNum = 1:length(channels)
    channel = channels{channelNum};
    filteredData.(channel) = filterEMGOneMuscle(loadedData.(channel), filter_config, fs, rectify);
end

%% Plot filtered EMG data
figFiltered = figure();
figFiltered = plotOneTrialData(filteredData, figFiltered);
annotateFigure(figFiltered, rawLoadedData.com, rawLoadedData.comtext, muscleNames);
figFiltered.WindowState = 'maximized';
drawnow;
pause(0.5);
convertXToSec(figFiltered);

%% Set the aesthetics of this plot
setAesthetics(figLoaded, aesthetics_config);
setAesthetics(figFiltered, aesthetics_config);

end

function [] = convertXToSec(figLoaded)

%% PURPOSE: FOR EACH AXES IN THE FIGURE, CONVERT THE XTICKLABELS TO SECONDS FROM SAMPLES

samplingRate = 2000;
allAxes = findobj(figLoaded,'Type','axes');
for i = 1:length(allAxes)
    ax = allAxes(i);
    xticks = get(ax, 'XTick');
    xtickLabels = xticks / samplingRate;
    set(ax, 'XTickLabel', xtickLabels);
    if ~isempty(ax.XLabel.String)
        ax.XLabel.String = 'Time (sec)';
    end
end

end