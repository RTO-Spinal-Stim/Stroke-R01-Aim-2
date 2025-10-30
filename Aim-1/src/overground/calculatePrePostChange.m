function [tableOut] = calculatePrePostChange(tableIn, formulaNum)

%% PURPOSE: CALCULATE THE CHANGE IN POST VS. PRE
% Inputs:
% tableIn: The input data
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
        formula = @(pre, post) ((post - pre) ./ pre) * 100;
        methodSuffix = 'PercDiff';
end

preStr = "PRE";
postStr = "POST";
prePostStr = "PrePost";

tableOut = table;

catTable = copyCategorical(tableIn);
catVars = catTable.Properties.VariableNames;
nonSubsetCatCols = {'Cycle', 'Side', 'Trial'};
catCols = catVars(~ismember(catVars, nonSubsetCatCols));

scalarColNames = getScalarColumnNames(tableIn);

preRowsIdx = ismember(string(catTable.PrePost), preStr);
preTable = tableIn(preRowsIdx,[catCols, scalarColNames']);
preTableCat = catTable(preRowsIdx,catVars);

uniquePreNames = unique(preTableCat(:, catCols),'rows','stable');

%% Average the PRE values in each group
meanPreTable = table;
for i = 1:height(uniquePreNames)
    currPreName = uniquePreNames(i,:);
    currPreIdx = tableContains(preTable, currPreName);
    tmpTable = currPreName;

    for colNum = 1:length(scalarColNames)
        colName = scalarColNames{colNum};
        currPreData = preTable.(colName)(currPreIdx);
        tmpTable.(colName) = mean(currPreData,'omitnan');
    end
    meanPreTable = [meanPreTable; tmpTable];
end
meanPreTableCat = copyCategorical(meanPreTable);
meanPreTableCat = removevars(meanPreTableCat, prePostStr);

%% Compute the change values in each group
postRowsIdx = ismember(string(tableIn.PrePost), postStr);
postTable = tableIn(postRowsIdx,[catVars, scalarColNames']);
prePostTable = removevars(postTable, prePostStr);
prePostTableCat = copyCategorical(prePostTable);
prePostTableUnique = removevars(prePostTableCat, nonSubsetCatCols);
prePostTableUnique = unique(prePostTableUnique, 'rows','stable');
catVarsNoPrePost = catVars(~ismember(catVars, {char(prePostStr)}));

prePostTableCatSubsetOnly = removevars(prePostTableCat, nonSubsetCatCols);
for i = 1:height(prePostTableUnique)    
    currPostRowIdx = ismember(prePostTableCatSubsetOnly, prePostTableUnique(i,:),'rows');
    currRows = prePostTable(currPostRowIdx, catVarsNoPrePost);
    currRowsSubset = removevars(currRows, nonSubsetCatCols);
    currMeanPreRowIdx = ismember(meanPreTableCat, currRowsSubset);
    assert(sum(currMeanPreRowIdx) == 1);
    tmpTable = currRows;

    for colNum = 1:length(scalarColNames)
        colName = scalarColNames{colNum};
        postValue = postTable.(colName)(currPostRowIdx);
        preMeanValue = meanPreTable.(colName)(currMeanPreRowIdx);
        tmpTable.([colName '_' methodSuffix]) = formula(preMeanValue, postValue);
    end
    tableOut = [tableOut; tmpTable];
end