function [tableOut] = calculatePrePostChangeAll(tableIn, formulaNum, levelNum)

%% PURPOSE: CALCULATE THE CHANGE IN POST VS. PRE FOR A TABLE WITH ALL SUBJECTS
% Inputs:
% tableIn: The input data for all subjects
% formulaNum: The number of the pre-post change formula to use
% levelNum: The number for the level to group the data at for PRE averaging
%
% Outputs:
% tableOut: The table of output data

disp('Calculating pre vs. post change');

if ~exist('formulaNum','var')
    formulaNum = 2;
end

switch formulaNum
    case 1
        formula = @(pre, post) post - pre;
        methodSuffix = 'Diff';
    case 2
        formula = @(pre, post) ((post - pre) / pre) * 100;
        methodSuffix = 'PercDiff';
end

tableOut = table;

preStr = '_PRE_';
postStr = '_POST_';

if ~exist('levelNum','var')
    levelNum = 4; % pre/post & SSV/FV combination
end

allColNames = {'Subject','Intervention','SessionOrder','Is_Stim','Frequency','Intensity','PrePost','Speed','Trial','Cycle'};
colNames = tableIn.Properties.VariableNames(~ismember(tableIn.Properties.VariableNames, [allColNames, {'Name'}]));

colNamesToSplitPreBy = {'Subject','Intervention','SessionOrder','Is_Stim','Frequency','Intensity','PrePost','Speed'};

nanFreqIdx = isnan(tableIn.Frequency);
tableIn.Frequency(nanFreqIdx) = 0;

tableInColNamesToSplitPreBy = tableIn(:, colNamesToSplitPreBy);
uniqueRows = unique(tableInColNamesToSplitPreBy, 'rows', 'stable');
preTable = uniqueRows(ismember(uniqueRows.PrePost, 'PRE'),:);
%% Average the PRE values in each group
meanPreTable = table;
for i = 1:height(preTable)
    currPreRow = preTable(i,:);
    currPreIdx = ismember(tableInColNamesToSplitPreBy, currPreRow, 'rows');
    tmpTable = removevars(currPreRow, 'PrePost');

    for colNum = 1:length(colNames)
        colName = colNames{colNum};
        currPreData = tableIn.(colName)(currPreIdx);
        tmpTable.(colName) = mean(currPreData,'omitnan');
    end
    meanPreTable = [meanPreTable; tmpTable];
end

%% Compute the change values in each group
postTable = tableInColNamesToSplitPreBy(ismember(tableInColNamesToSplitPreBy.PrePost, 'POST'), :);
postTable = removevars(postTable, 'PrePost');
postTableData = tableIn(ismember(tableIn.PrePost, 'POST'), :);
preTable = removevars(preTable, 'PrePost');
for i = 1:height(postTable)
    tmpTable = postTableData(i,:);
    currMeanPreRow = ismember(preTable, postTable(i,:), 'rows');
    assert(sum(currMeanPreRow) == 1);

    for colNum = 1:length(colNames)
        colName = colNames{colNum};
        postValue = postTableData.(colName)(i);
        preMeanValue = meanPreTable.(colName)(currMeanPreRow);
        tmpTable.([colName '_' methodSuffix]) = formula(preMeanValue, postValue);
    end
    tableOut = [tableOut; tmpTable];
end

tableOut = removevars(tableOut, {'PrePost', 'Name'});
% nanFreqIdx = tableOut.Frequency == 0;
% tableOut.Frequency(nanFreqIdx) = NaN;