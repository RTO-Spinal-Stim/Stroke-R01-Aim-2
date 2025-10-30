function [tableOut] = combineSubjectTables(subjectList, pathTemplate, varName, splitNameColumns, colsToConvertToNumeric)

%% PURPOSE: COMBINE EACH PARTICIPANT'S TABLE OF PROCESSED DATA FROM THEIR .MAT FILE INTO ONE TABLE
% Inputs:
% subjectList: Cell array of the subject names
% pathTemplate: The path where each subject's .mat file is saved, with a
% placeholder for the subject ID '{subject}'
% varName: The variable name in the .mat file to load
% splitNameColumns: The column names to split the Name column into. Must be
% in the proper order!
% colsToConvertToNumeric: The column names to convert to numeric (e.g.
% 'cycle1' to '1'
%
% tableOut: The combined table of all participants.
%
% 1. Scalar values only
% 2. Split the 'Name' column by underscores, one column per part of the name

tableOut = table;
for subNum = 1:length(subjectList)
    subject = subjectList{subNum};
    fullPath = strrep(pathTemplate, '{subject}', subject);

    if ~isfile(fullPath)
        disp(['File missing: ' fullPath]);
        continue;
    end

    disp(['Loading Variable: ' varName ' From: ' fullPath]);

    dataTable = load(fullPath, varName);
    dataTable = dataTable.(varName);

    % Get the column names that are scalar. Either a scalar numeric/char,
    % or a scalar struct with fields that are scalar numeric/char.
    scalarColumnNames = getScalarColumnNames(dataTable);

    % Put the scalar data into the table.
    for rowNum = 1:height(dataTable)
        tmpTable = table;
        % For each row, distribute the 'Name' column to multiple columns
        parsedName = strsplit(dataTable.Name(rowNum), '_');
        assert(length(splitNameColumns) == length(parsedName));
        for i = 1:length(splitNameColumns)
            tmpTable.(splitNameColumns{i}) = parsedName(i);
        end
        % Store the data to the proper columns
        for colNum = 1:length(scalarColumnNames)
            colNameOrig = scalarColumnNames{colNum};
            currData = dataTable.(colNameOrig)(rowNum);
            if ~isstruct(currData)
                tmpTable.(colNameOrig) = currData;
            else
                fldNames = fieldnames(currData);
                for fldNum = 1:length(fldNames)
                    colName = [colNameOrig '_' fldNames{fldNum}];
                    tmpTable.(colName) = currData.(fldNames{fldNum});
                end
            end
        end
        tableOut = [tableOut; tmpTable];
    end

end

%% Convert the specified columns to numeric
numericRegex = '\d+';
for i = 1:length(colsToConvertToNumeric)
    colName = colsToConvertToNumeric{i};
    numericVals = NaN(height(tableOut),1);
    for j = 1:height(tableOut)
        charNumericValArray = regexp(char(tableOut.(colName)(j)), numericRegex, 'match');
        charNumericVal = strjoin(charNumericValArray, '');
        numericVals(j) = str2double(charNumericVal);
    end
    tableOut.(colName) = numericVals;
end

%% Sort the table
tableOut = sortrows(tableOut, splitNameColumns);
