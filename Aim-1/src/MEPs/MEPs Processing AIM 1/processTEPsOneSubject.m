function [tepsResultTableOneSubject] = processTEPsOneSubject(tepsLogAll, subject, config, currSubjFolder, correctChannelsJSONPath)

%% PURPOSE: PROCESS TEPs FOR ONE SUBJECT. PART A IN NICOLE'S PIPELINE FOR STROKE SPINAL STIM.
% Inputs:
% tepsLog: TEPs log table
% subject: Subject name
% tepColNamesConfig: Struct of column names for TEPs log
% currSubjFolder: The folder path for the current subject's TEPs data.
% correctChannelsJSONPath: Path to the JSON file for correcting the EMG
% channels
% 
% Outputs:
% tepsTable: Table of processed TEPs results.

%% Config
TEPcolNamesConfig = config.TEPS_LOG_COLUMN_NAMES;
subjectNameHeader = TEPcolNamesConfig.SUBJECT_NAME;
fileNameHeader = TEPcolNamesConfig.TEP_FILENAME;
sessionCodeHeader = TEPcolNamesConfig.SESSION_CODE;

%% Get the numeric part of the subject name
numericRegex = '\d+';
subjectNum = regexp(subject, numericRegex, 'match');
subjectNum = subjectNum{1};

%% Filter TEPS log for one subject.
tepsLog = filterTEPsLogForOneSubject(tepsLogAll, subjectNameHeader, subjectNum);
correctedChannelsStruct = jsondecode(fileread(correctChannelsJSONPath));
correctedChannelsStructSubject = struct;
if isfield(correctedChannelsStruct, subject)
    correctedChannelsStructSubject = correctedChannelsStruct.(subject);
end
tepsResultTableOneSubject = table;
for i = 1:height(tepsLog)    
    fileName = tepsLog.(fileNameHeader){i};
    sessionCode = tepsLog.(sessionCodeHeader){i};
    trialFilePath = fullfile(currSubjFolder, sessionCode, fileName);
    row = processTEPsOneFile(config, tepsLog(i,:), trialFilePath, correctedChannelsStructSubject);  
    tepsResultTableOneSubject = [tepsResultTableOneSubject; row];    
end

% Move the Name to the first column
% tepsResultTableOneSubject.Name = tepsLog.(fileNameHeader);
% tepsResultTableOneSubject = [tepsResultTableOneSubject(:,2:end), tepsResultTableOneSubject(:,1)];

curr_subj_save_path = fullfile(config.SAVE_FOLDER, subject);
subjectSavePathPartA = fullfile(curr_subj_save_path, config.SAVE_FILENAMES.A);
save(subjectSavePathPartA, 'tepsResultTableOneSubject');