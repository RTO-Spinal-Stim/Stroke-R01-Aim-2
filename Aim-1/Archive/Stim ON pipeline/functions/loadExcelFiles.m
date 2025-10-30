function allData = loadExcelFiles(folderStruct)
    % List all Excel files in the folder
%     excelFiles = dir(fullfile(folderPath, '*.xlsx'));

    % Get the field names (structs) within folderStruct
      allStructs = fieldnames(folderStruct);
      
    % Initialize a struct array to store the data from each Excel file
    allData = struct();

    % Loop through each Excel file and load data
    for structIndex = 1:length(allStructs)
       
%         excelFileName = excelFiles(structIndex).name;
       
        % Load the Excel file
%         data = xlsread(fullfile(folderPath, excelFileName));
          data = folderStruct.(allStructs{structIndex}).num;

        % Store the data in the allData struct array
        allData.(allStructs{structIndex}) = data; % Remove the '.xlsx' extension from the file name
    end
end
