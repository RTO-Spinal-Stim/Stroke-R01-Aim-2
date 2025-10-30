function [tableOut] = widenTableBySides(tableIn, sideColName, factorColNames, prePost, summType)

%% PURPOSE: WIDEN THE TABLE SO THAT EACH COLUMN HAS THE SIDE PREPENDED TO IT. RESULTS IN TWICE AS MANY FEATURE COLUMNS, AND REMOVES THE SIDE COLUMN.
% Inputs:
% tableIn: The input data table
% sideColName: The column name with the side information
% factorColNames: The column names to use as factors
% prePost: struct with one field. Field is the column name, value is either 'PRE' or 'POST'
% summType: 'mean' or 'median' summary per trial
%
% Outputs:
% tableOut: The output data table

disp('Widening tables by sides');

tableOut = table;

allVarNames = tableIn.Properties.VariableNames;
prePostColName = fieldnames(prePost);
prePostRowsIdx = ismember(tableIn.(prePostColName{1}), prePost.(prePostColName{1}));
tableIn = tableIn(prePostRowsIdx,:);
factorTable = tableIn(:, ismember(allVarNames, [factorColNames, prePostColName]));
uniqueFactorTable = unique(factorTable, 'rows');

firstOutcomeVarColNum = find(ismember(allVarNames, sideColName)) + 1;

for i = 1:height(uniqueFactorTable)
    currFactorRow = uniqueFactorTable(i,:);

    % Get the index of the rows for the current factor set
    currFactorIdx = ismember(factorTable, currFactorRow, 'rows');

    currFactorTable = tableIn(currFactorIdx,:);

    % Get the U and A tables separately
    uIdx = ismember(currFactorTable.(sideColName), 'U');
    aIdx = ~uIdx;

    uTable = currFactorTable(uIdx, firstOutcomeVarColNum:end);
    aTable = currFactorTable(aIdx, firstOutcomeVarColNum:end);

    % Summarize each column of the U and A data, and put them into a separate table
    varNames = uTable.Properties.VariableNames;
    tmpTableOut = tableIn(currFactorIdx,1:firstOutcomeVarColNum-1);
    tmpTableOut = unique(removevars(tmpTableOut, {sideColName, 'Cycle'}),'rows');
    tmpTableOut = tmpTableOut(1,:); % Because unique() fails when 'Frequency' column is NaN
    for varNum = 1:length(varNames)
        varName = varNames{varNum};
        if strcmpi(summType, 'mean')
            uSumm = mean(uTable.(varName),'omitnan');
            aSumm = mean(aTable.(varName),'omitnan');
        elseif strcmpi(summType, 'median')
            uSumm = median(uTable.(varName), 'omitnan');
            aSumm = median(aTable.(varName), 'omitnan');
        end
        tmpTableOut.([varName '_U']) = uSumm;
        tmpTableOut.([varName '_A']) = aSumm;
    end
    
    tableOut = [tableOut; tmpTableOut];

end