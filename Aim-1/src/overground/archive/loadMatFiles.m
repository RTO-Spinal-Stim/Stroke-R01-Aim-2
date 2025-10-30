function allData = loadMatFiles(folderStruct)

% PURPOSE: Parse each of the muscles from the vector of EMG data that is
% loaded from Delsys by default.

% Get the field names of each file within folderStruct
structFieldNamesFileNames = fieldnames(folderStruct);

% Initialize a struct array to store the data from each file
allData = struct();

% Loop through each MAT file and load data
for structIndex = 1:length(structFieldNamesFileNames)
    
    structFieldFileName = structFieldNamesFileNames{structIndex};
    
    % Load Data
    data = folderStruct.(structFieldNamesFileNames{structIndex});
    
    % Extract muscle names from the loaded data
    muscle = strrep(cellstr(data.titles), '''', '');
    muscle = muscle(1:10);
    
    % Create a struct for the current file
    current = struct();
    
    % Loop through muscles and extract data for each
    for i = 1:length(muscle)
        startData = data.datastart(i);
        endData = data.dataend(i);
        if startData==-1
            continue;
        end
        current.(muscle{i}) = data.data(startData:endData);
    end
    
    % Store the current struct in the allData struct array
    allData.(structFieldFileName) = current; % Remove the '.mat' extension from the file name
end
