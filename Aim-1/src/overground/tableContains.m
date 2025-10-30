function [matchIdx] = tableContains(tableWithMoreColumns, tableWithFewerColumns)

%% PURPOSE: RETURN THE ROWS WHERE ALL THE VALUES OF THE TABLE WITH FEWER COLUMNS ARE FOUND IN THE TABLE WITH MORE COLUMNS.

% Using innerjoin with specific keys
matchTable = innerjoin(tableWithMoreColumns, tableWithFewerColumns, 'Keys', tableWithFewerColumns.Properties.VariableNames);

% Handle columns that are nonscalar
tableWithMoreColumnsCat = copyCategorical(tableWithMoreColumns);
matchTableCat = copyCategorical(matchTable);

matchIdx = ismember(tableWithMoreColumnsCat, matchTableCat, 'rows');