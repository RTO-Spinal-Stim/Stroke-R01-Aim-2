% Run from src/tx folder
configPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01-Aim-2\src\overground\config_Aim2.json';
config = jsondecode(fileread(configPath));

addpath(genpath('Y:\LabMembers\MTillman\MATLAB_FileExchange_Repository'));

runConfig = toml.map_to_struct(toml.read('subjects_to_run.toml'));
allSubjects = runConfig.subjects.run;

addpath(genpath('Y:\LabMembers\MTillman\GitRepos\Stroke-R01-Aim-2\Aim-1\src\overground'));

%% Iterate over each subject
doPlot = false;
for subNum = 1:length(allSubjects)
    subject = allSubjects{subNum};    
    subjectSavePath = fullfile(config.PATHS.ROOT_SAVE, subject, [subject '_' config.PATHS.SAVE_FILE_NAME]);
    disp(['Now running subject (' num2str(subNum) '/' num2str(length(allSubjects)) '): ' subject]);
    mainOneSubject_TX_Aim2; % Run the main pipeline.
end

%% Load the 10MWT REDCap report
tenMWTreportPath = "Y:\Spinal Stim_Stroke R01\AIM 2\Subject Data\REDCap Reports\SpinalStimStrokeAim2-10MWTAll_DATA_2025-09-23_1303.csv";
tenMWTreportTable = load10MWTREDCapReport(tenMWTreportPath);

%% Load the cycleTable and matchedCycleTable from all subjects
configPath = 'Y:\LabMembers\MTillman\GitRepos\Stroke-R01-Aim-2\src\overground\config_Aim2.json';
config = jsondecode(fileread(configPath));
categoricalCols = {'Subject','Intervention','Speed','Trial','Cycle','StartFoot'};
cycleTableAll = readtable(config.TX.PATHS.ALL_DATA_CSV);
for i = 1:length(categoricalCols)
    cycleTableAll.(categoricalCols{i}) = categorical(cycleTableAll.(categoricalCols{i}));
end

%% Replace 'StartFoot' with 'Side'
categoricalCols = {'Subject','Intervention','Speed','Trial','Cycle','Side'};
if ismember('StartFoot', cycleTableAll.Properties.VariableNames)
    cycleTableAll.Side = cycleTableAll.StartFoot;
    cycleTableAll = removevars(cycleTableAll, 'StartFoot');
end
cycleTableAll = movevars(cycleTableAll,'Side','After','Cycle');

%% Calculate symmetries
formulaNum = 6; % computing Sym using the original equation * 100
[colNamesL, colNamesR] = getLRColNames(cycleTableAll);
% Compute the symmetry values
nonSubsetCatVars = {'Cycle','Side'};
cycleTableAllSym = calculateSymmetryAll(cycleTableAll, '_Sym', formulaNum, nonSubsetCatVars);
categoricalColsTrial = {'Subject','Intervention','Speed','Trial'};

%% Adjust intervention name to mapped names
interventions = config.TX.INTERVENTION_FOLDERS;
mapped_interventions = config.TX.MAPPED_INTERVENTIONS;
intervention_map = containers.Map(interventions, mapped_interventions);
for i = 1:height(cycleTableAllSym)
    intervention = string(cycleTableAllSym.Intervention(i));
    cycleTableAllSym.Intervention(i) = intervention;
end

%% Adjust the L & R sides to "U" and "A" for unaffected and affected sides
subjectDemographicsPath = "Y:\Spinal Stim_Stroke R01\AIM 2\Subject Data\Subject Demographics Aim 2.xlsx";
demographics = readExcelFileOneSheet(subjectDemographicsPath, 'Subject', 'Sheet1');
colNames = {'Subject', 'PareticSide'};
inputTableSideCol = 'Side';
demographicsSideCol = 'PareticSide';
allColNames = demographics.Properties.VariableNames;
colNamesIdx = ismember(allColNames, colNames);
reducedDemographics = unique(demographics(:, colNamesIdx), 'rows');
% Omit the subjects from demographics that are not in the data tables
subjectIdx = ismember(string(reducedDemographics.Subject), string(cycleTableAll.Subject));
reducedDemographics(~subjectIdx,:) = [];
cycleTableAllUA = convertLeftRightSideToAffectedUnaffected(cycleTableAllSym, reducedDemographics, inputTableSideCol, demographicsSideCol);

%% Save the unaffected and affected side tables
tablesPathPrefixMergedUA = 'Y:\LabMembers\MTillman\SavedOutcomesAim2\TX\MergedTablesAffectedUnaffected';
writetable(cycleTableAllUA, fullfile(tablesPathPrefixMergedUA, 'unmatchedCycles.csv'));