function [allTrials] = checkTrialOrder(subjectDataPath, subjectList)

%% PURPOSE: RETURN A LIST OF TRIALS THAT ARE OUT OF ORDER IN THE GAITRITE DATA.
% Checks the GaitRite, XSENS, and EMG data. This code is intended to be run
% as a standalone!
% Inputs:
% subjectDataPath: Path to the subject data folder
% subjectList: Cell array of subject names to go through
%
% Outputs:
% allTrials: Cell array of all trial names that are out of order

allTrials = {};

for i = 1:length(subjectList)
    subject = subjectList{i};
    disp(['Subject: ' subject]);
    subjectFolderPath = fullfile(subjectDataPath, subject);
    subjectTrials = checkTrialOrderOneSubject(subjectFolderPath);
    for subjectNum = 1:length(subjectTrials)
        subjectTrials{subjectNum} = [subject '_' subjectTrials{subjectNum}];
    end
    allTrials = [allTrials; subjectTrials];
end

end

function [trialList] = checkTrialOrderOneSubject(subjectFolderPath, interventions)

%% PURPOSE: CHECK THE GAITRITE TRIAL ORDER FOR ONE SUBJECT
% Inputs:
% subjectFolderPath: The full file path to one subject's data folder
% interventions: Cell array of the intervention folder names
%
% Outputs:
% trialList: Cell array of 
if ~exist('interventions','var')
    interventions = {'SHAM1','SHAM2','30_RMT','30_TOL','50_RMT','50_TOL'};
end
trialList = {};
for i = 1:length(interventions)
    intervention = interventions{i};
    disp(['Intervention: ' intervention]);
    interventionCombs = checkTrialOrderOneSubjectOneIntervention(subjectFolderPath, intervention);
    combNames = fieldnames(interventionCombs); % e.g. 'POST_FV'
    for combNum = 1:length(combNames)
        combName = combNames{combNum};
        for trialCount = 1:length(interventionCombs.(combName))            
            trialNum = interventionCombs.(combName)(trialCount);
            trialName = [intervention '_' combName '_' num2str(trialNum)];
            if trialNum ~= trialCount
                trialList = [trialList; {trialName}];
            end
        end
    end
end

end

function [combs] = checkTrialOrderOneSubjectOneIntervention(subjectFolderPath, intervention, prePosts, speeds)

prePosts = {'PRE','POST'};
speeds = {'SSV','FV'};
%% XSENS
xsensStruct = struct;
xsensFolderPath = fullfile(subjectFolderPath, 'XSENS', intervention);
fileList = dir(fullfile(xsensFolderPath, '*.xlsx'));
fileNames = {fileList.name};
for prePostNum = 1:length(prePosts)
    prePost = prePosts{prePostNum};
    for speedNum = 1:length(speeds)
        speed = speeds{speedNum};
        substr = [prePost '_' speed];
        disp(['Speed: ' speed ' PrePost: ' prePost]);
        currCombFilesIdx = contains(fileNames, substr);
        currCombFiles = fileNames(currCombFilesIdx);
        currCombFiles = sort(currCombFiles); % In numeric order
        savedTimes = datetime(NaT(length(currCombFiles),1),'TimeZone','America/Chicago');
        for fileNum = 1:length(currCombFiles)
            currFile = currCombFiles{fileNum};
            [raw_data, header_row, cell_data] = xlsread(fullfile(xsensFolderPath, currFile), 'General Information');
            fullDate = cell_data{4,2};
            spaceIdx = strfind(fullDate, ' ');
            timeSaved = fullDate(spaceIdx(1)+1:end);
            timeSavedDateTime = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'UTC');
            timeSavedDateTime.TimeZone = 'America/Chicago';
            savedTimes(fileNum) = timeSavedDateTime;
        end
        [~,sortedOrder] = sort(savedTimes);
        if ~isequal(sortedOrder', 1:length(sortedOrder))
            xsensStruct.(substr) = sortedOrder';
        end
    end
end

%% Delsys
delsysFolderPath = fullfile(subjectFolderPath, 'Delsys', intervention);
delsysStruct = struct;
fileList = dir(fullfile(delsysFolderPath, '*.adicht'));
fileNames = {fileList.name};
for prePostNum = 1:length(prePosts)
    prePost = prePosts{prePostNum};
    for speedNum = 1:length(speeds)
        speed = speeds{speedNum};
        substr = [prePost '_' speed];
        currCombFilesIdx = contains(fileNames, substr);
        currCombFiles = fileNames(currCombFilesIdx);
        currCombFiles = sort(currCombFiles); % In numeric order
        savedTimes = datetime(NaT(length(currCombFiles),1),'TimeZone','America/Chicago');
        for fileNum = 1:length(currCombFiles)
            currFile = currCombFiles{fileNum};
            currFileIdx = contains(fileNames, currFile);
            fullDate = fileList(currFileIdx).date;
            spaceIdx = strfind(fullDate, ' ');
            timeSaved = fullDate(spaceIdx(1)+1:end);            
            % Missing AM or PM, so add it here.
            colonIdx = strfind(timeSaved, ':');
            hrNum = str2double(timeSaved(1:colonIdx(1)-1));
            if hrNum >= 12                
                timeSaved = [timeSaved ' PM'];
                if hrNum >= 13
                    hrNum = hrNum - 12;
                    timeSaved = [num2str(hrNum) timeSaved(3:end)];
                end
            else
                timeSaved = [timeSaved ' AM'];
            end
            timeSavedDateTime = datetime(timeSaved, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'America/Chicago');
            savedTimes(fileNum) = timeSavedDateTime;
        end
        [~,sortedOrder] = sort(savedTimes);
        if ~isequal(sortedOrder', 1:length(sortedOrder))
            delsysStruct.(substr) = sortedOrder';
        end
    end
end

%% GaitRite
gaitRiteFolderPath = fullfile(subjectFolderPath, 'Gaitrite', intervention);
gaitRiteStruct = struct;
fileList = dir(fullfile(gaitRiteFolderPath, '*.xlsx'));
fileNames = {fileList.name};
for prePostNum = 1:length(prePosts)
    prePost = prePosts{prePostNum};
    for speedNum = 1:length(speeds)
        speed = speeds{speedNum};
        substr = [prePost '_' speed];
        currCombFileIdx = contains(fileNames, substr);
        currCombFile = fileNames{currCombFileIdx};
        gaitRitePath = fullfile(gaitRiteFolderPath, currCombFile);
        [num_data, txt_data, cell_data] = xlsread(gaitRitePath);
        header_row_num = find(contains(txt_data(:,1), 'ID'),1,'first');
        header_row = txt_data(header_row_num,:);
        for i = 1:length(header_row)
            header_row{i} = strtrim(header_row{i});
        end
        timeColIdx = ismember(header_row, 'Time');

        trial_times = unique(txt_data(header_row_num+1:size(num_data,1)+header_row_num, timeColIdx), 'stable');
        savedTimes = datetime(NaT(length(trial_times),1),'TimeZone','America/Chicago');
        for i = 1:length(trial_times)
            fullDate = trial_times{i};
            spaceIdx = strfind(fullDate, ' ');
            savedTime = fullDate(spaceIdx(1)+1:end);
            savedTimes(i) = datetime(savedTime, 'InputFormat', 'h:mm:ss a', 'TimeZone', 'America/Chicago');
        end
        [~,sortedOrder] = sort(savedTimes);
        if ~isequal(sortedOrder', 1:length(sortedOrder))
            gaitRiteStruct.(substr) = sortedOrder';
        end
    end
end

gaitRiteCombs = fieldnames(gaitRiteStruct);
xsensCombs = fieldnames(xsensStruct);
delsysCombs = fieldnames(delsysStruct);

assert(isempty(gaitRiteCombs)); % GaitRite is always "in order", but that order is wrong if it doesn't match XSENS & Delsys

assert(isequal(delsysCombs, xsensCombs));
% Check that the orders listed in Delsys and XSENS are identical
for i = 1:length(delsysCombs)
    currComb = delsysCombs{i};
    xsensOrder = xsensStruct.(currComb);
    delsysOrder = delsysStruct.(currComb);
    assert(isequal(delsysOrder, xsensOrder));
end

combs = xsensStruct;

end