missingFiles = identifyMissingDataPaths(jsondecode(fileread('Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Troubleshooting\Missing_Files\missingFilesConfig.json')));
missingFilesTable = table;
subjects = cell(size(missingFiles));
dataTypes = cell(size(missingFiles));
interventions = cell(size(missingFiles));
fileNames = cell(size(missingFiles));
for i = 1:length(missingFiles)
    splitPath = strsplit(missingFiles{i},filesep);
    subjects{i} = splitPath{5};
    dataTypes{i} = splitPath{6};
    interventions{i} = splitPath{7};
    fileNames{i} = splitPath{8};
end

missingFilesTable.Subjects = subjects;
missingFilesTable.DataTypes = dataTypes;
missingFilesTable.Interventions = interventions;
missingFilesTable.FileNames = fileNames;
missingFilesTable.Paths = missingFiles;
missingFilesTable.Reason = cell(size(missingFiles));
writetable(missingFilesTable, 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\missingFiles_250612.xlsx');