function allData = loadXsens(folderPath)
    % List all Excel files in the folder containing the word 'PRE' in the file name
    excelFiles = dir(fullfile(folderPath, '*GAITRITE*.xlsx'));

    % Initialize a struct array to store the data from each Excel file
    allData = struct();

    % Loop through each Excel file and load data from the second sheet
    for fileIndex = 1:length(excelFiles)
        excelFileName = excelFiles(fileIndex).name;

        % Load the second sheet of the Excel file
        [~, ~, data] = xlsread(fullfile(folderPath, excelFileName), 2);

        % Extract headers from the first row
        headers = data(1,:);

        % Remove the first row (headers) from the data
        data = data(2:end,:);

        % Convert the data into a table with headers
        dataTable = cell2table(data, 'VariableNames', headers);

        % Store the data in the allData struct array
        allData.(excelFileName(1:end-5)) = dataTable; % Remove the '.xlsx' extension from the file name
    end
end
