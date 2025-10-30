function [varargout] = checkTrialOrderAllInterventions(gaitRiteTable, otherTrialTables, colNameSubstr)

%% PURPOSE: CHECK THE GAITRITE TRIAL ORDER FOR ONE SUBJECT
% Inputs:
% gaitRiteTable: The table of GaitRite data, where each row is one trial
% otherTrialTables: Cell array of the tables of the other hardwares' data, where each row
% is one trial.
% colNameSubstr: The substring that must be present in exactly one column name in each table
%
% Outputs:
% varargout: The rearranged tables, in the same order as the
% otherTrialTables cell array

disp('Reordering the trials that are out of order.')

if ~exist('colNameSubstr','var')
    colNameSubstr = 'DateTimeSaved';
end

% Check for the proper column names
grVarNames = gaitRiteTable.Properties.VariableNames;
grDateSavedColLogical = contains(grVarNames, colNameSubstr);
if sum(grDateSavedColLogical) ~=1
    error(['GaitRite trials table must contain exactly one column name matching: ' colNameSubstr]);
end

otherTablesDateSavedColLogical = cell(length(otherTrialTables),1);
reorderedOtherTrialTables = cell(1,length(otherTrialTables));
for i = 1:length(otherTrialTables)
    otherTableVarNames = otherTrialTables{i}.Properties.VariableNames;
    otherTablesDateSavedColLogical{i} = contains(otherTableVarNames, colNameSubstr);
    if sum(otherTablesDateSavedColLogical{i}) ~= 1
        error(['Other trials table #' num2str(i) ' must contain exactly one column name matching: ' colNameSubstr]);
    end
    if height(otherTrialTables{i}) ~= height(gaitRiteTable)
        error(['Other trials table #' num2str(i) ' must match GaitRite table height!']);
    end
    reorderedOtherTrialTables{i} = table; % Initializing
end

gaitRiteTableCategorical = copyCategorical(gaitRiteTable);
categoricalVarNames = gaitRiteTableCategorical.Properties.VariableNames;
lastCategorical = categoricalVarNames(end);
gaitRiteTableCategoricalNoLast = gaitRiteTableCategorical;
gaitRiteTableCategoricalNoLast(:, lastCategorical) = []; % StartFoot. This should not be used for filtering
uniqueCombs = unique(gaitRiteTableCategoricalNoLast,'rows','stable');
for i = 1:height(uniqueCombs)    
    currComb = uniqueCombs(i,:);
    currRowsIdx = tableContains(gaitRiteTableCategorical, currComb); 
    currGRTable = gaitRiteTable(currRowsIdx, :);
    currGRTableDateTimes = currGRTable(:,grDateSavedColLogical | ismember(grVarNames, categoricalVarNames)); % DateSaved & categorical columns only
    joinedTable = currGRTableDateTimes;
    % Get the column name
    currGRVarNames = currGRTableDateTimes.Properties.VariableNames;
    grDateTimeColName = currGRVarNames(~ismember(currGRVarNames, categoricalVarNames));
    grDateTimeColName = grDateTimeColName{1};
    
    % Join the tables together with all of the saved dates
    for tableNum = 1:length(otherTrialTables)
        currTable = otherTrialTables{tableNum};        
        currTableCategorical = copyCategorical(currTable);

        currRowsIdx = tableContains(currTableCategorical, currComb);
        currColsIdx = otherTablesDateSavedColLogical{tableNum} | ismember(otherTrialTables{tableNum}.Properties.VariableNames, categoricalVarNames); % DateSaved & Name columns only
        currOtherTable = currTable(currRowsIdx,currColsIdx);        
        joinedTable = join(joinedTable, currOtherTable, 'Keys', categoricalVarNames);
    end

    % Order the saved dates
    joinedTableOrders = joinedTable;
    joinedTableVarNames = joinedTable.Properties.VariableNames;
    joinedTableVarNames(ismember(joinedTableVarNames, categoricalVarNames)) = [];
    % All the columns being sorted here are date times.
    for colNum = 1:length(joinedTableVarNames)
        [~,orderNums] = sort(joinedTable.(joinedTableVarNames{colNum}));
        joinedTableOrders.(joinedTableVarNames{colNum}) = orderNums;
    end

    % Check that all of the non-gaitrite orders match
    joinedTableOrdersGRRemoved = removevars(joinedTableOrders, [{grDateTimeColName}, categoricalVarNames]);
    ordersGRRemoved = table2array(joinedTableOrdersGRRemoved);
    joinedTableGRRemoved = removevars(joinedTable, [{grDateTimeColName}, categoricalVarNames]);
    datetimesGRRemoved = table2array(joinedTableGRRemoved);
    if ~all(diff(ordersGRRemoved,1,2) == 0) && ~any(isnat(datetimesGRRemoved), 'all')
        error('Not all of the non-GaitRite hardwares agree on trial order!');
    end

    if any(isnat(datetimesGRRemoved), 'all')
        orderToUse = (1:size(ordersGRRemoved,1))'; % No change if unreliable data
    else
        % Get the order to rearrange the rows
        orderToUse = ordersGRRemoved(:,1);
    end
    
    % Perform the rearrangement
    for tableNum = 1:length(otherTrialTables)
        currTable = otherTrialTables{tableNum};
        currTableCategorical = copyCategorical(currTable);
        currRowsIdx = tableContains(currTableCategorical, currComb);
        currTableRows = currTable(currRowsIdx,:);
        currTableRowsReordered = currTableRows(orderToUse,:);
        reorderedOtherTrialTables{tableNum} = [reorderedOtherTrialTables{tableNum}; currTableRowsReordered];
    end

end

varargout = reorderedOtherTrialTables;

end