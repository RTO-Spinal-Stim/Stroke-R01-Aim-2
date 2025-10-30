function allData = loadExcelFiles(folderStruct)

% PURPOSE: Extract the ".num" field, which is what's used for analysis.

% Get the field names (structs) within folderStruct
structFieldNamesFileNames = fieldnames(folderStruct);

% Initialize a struct array to store the data from each Excel file
allData = struct();

% Loop through each Excel file
for structIndex = 1:length(structFieldNamesFileNames)
    
    structFieldFileName = structFieldNamesFileNames{structIndex};
    
    % Store the data in the allData struct array
    allData.(structFieldFileName) = folderStruct.(structFieldFileName).num;
end
