function [tableOut] = join10MWTSpeedToCycleLevelTable(tepsLogPath, cycleTablePath, configPath, tepsNameColumns, cycleNamesColumns)

%% PURPOSE: JOIN THE 10MWT SPEEDS INTO THE CYCLE LEVEL TABLE.
% Inputs:
% tepsLogPath: The full file path to the TEPs log, which contains the 10MWT speeds
% cycleTablePath: The full file path to the cycle-level table that the 10MWT speeds will be added to
% tepsNameColumns: The column names in the tepsLog to merge into the "Name"
% column. Must be in the proper order to match the cycleNamesColumns.
% cycleNamesColumns: The column names in the cycleTable to merge into the
% "Name" column. Must be in the proper order to match the tepsNameColumns.
%
% Outputs:
% tableOut: The cycle level table with the 10MWT speeds

pattern = '^(FV|SSV)[0-9]_s';

if ~exist('tepsNameColumns','var')
    tepsNameColumns = {'Subject','Intervention','Pre_Post','Speed','Trial'};
end

if ~exist('cycleNamesColumns','var')
    cycleNamesColumns = {'Subject','Intervention','PrePost','Speed','Trial'};
end

config = jsondecode(fileread(configPath));

%% Read in the data
tepsLog = readExcelFileOneSheet(tepsLogPath, 'Subject', 'Sheet1');
cycleTable = readtable(cycleTablePath);

%% Add "SS" to the Subject name in TEPs log
tepsLog.Subject = "SS" + convertCharsToStrings(tepsLog.Subject);

%% Filter for subjects
subjects = unique(string(cycleTable.Subject),'stable');
existSubjectIdx = ismember(tepsLog.Subject, subjects);
tepsLog(~existSubjectIdx,:) = [];

%% Map the intervention names
mapped_fields = containers.Map(config.INTERVENTION_FOLDERS, config.MAPPED_INTERVENTION_FIELDS);
for i = 1:height(tepsLog)
    tepsLog.Intervention(i) = {mapped_fields(tepsLog.SessionCode{i})};
end

%% Put the speed data into column form
allVarNames = tepsLog.Properties.VariableNames;
matchResults = regexp(allVarNames, pattern, 'once');
speedColIdx = ~cellfun('isempty', matchResults);
varNamesToRemoveIdx = ~ismember(allVarNames, tepsNameColumns) & ~speedColIdx;
tepsLogNameSpeed = removevars(tepsLog, allVarNames(varNamesToRemoveIdx));

% Get only the name columns
tepsLogName = tepsLogNameSpeed(:, ismember(tepsLogNameSpeed.Properties.VariableNames, tepsNameColumns));

% Duplicate the table, so that there's one row per trial.
tepsLogNameTrialRows = tepsLogName(repmat(1:height(tepsLogName),3,1),:);
tepsLogTall = table;
for i = 1:height(tepsLogName)
    currRow = tepsLogName(i,:);
    currTrialRowsIdxNum = find(ismember(tepsLogNameTrialRows, currRow, 'rows'));
    tmpTable = tepsLogNameTrialRows(repmat(currTrialRowsIdxNum,2,1),:);
    tmpTable.Trial = repmat((1:3)',2,1);
    tmpTable.Speed = [repmat({'SSV'},3,1); repmat({'FV'},3,1)];
    tmpTable.TenMWT = [tepsLogNameSpeed.SSV1_s(i); tepsLogNameSpeed.SSV2_s(i); tepsLogNameSpeed.SSV3_s(i); ...
        tepsLogNameSpeed.FV1_s(i); tepsLogNameSpeed.FV2_s(i); tepsLogNameSpeed.FV3_s(i)];
    tepsLogTall = [tepsLogTall; tmpTable];
end

%% Join the speed data in the tepsLog with the cycleTable
tepsLogTall.PrePost = tepsLogTall.Pre_Post;
tepsLogTall = removevars(tepsLogTall, 'Pre_Post');
catVars = tepsLogTall.Properties.VariableNames;
catVars(ismember(catVars,{'TenMWT'})) = [];
tableOut = innerjoin(cycleTable, tepsLogTall, 'Keys', catVars);