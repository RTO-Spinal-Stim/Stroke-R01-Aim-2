function [indVarNames, VIFs, VIFsMatrix] = independentVarsFromVIF(tableIn, cutoff)

%% PURPOSE: IDENTIFY WHICH VARIABLES ARE INDEPENDENT FROM ONE ANOTHER.
% Inputs:
% tableIn: The input table of data with numeric columns only.
% cutoff: VIF threshold. Default = 10
%
% Outputs:
% varNames: The unique variable names in the table, where VIF is below the threshold.
% VIFs: The VIF's for each variable. Each column is one regressor variable.

if ~exist('cutoff','var')
    cutoff = 10;
end

collinearVarNames = {};
varNames = tableIn.Properties.VariableNames;
numVars = length(varNames);
VIFsMatrix = NaN(numVars, numVars);
VIFs = NaN(numVars, 1);
foundIndVarNames = false;
for i = 1:numVars

    % Remove the variables that were already labelled as collinear
    currTable = removevars(tableIn, collinearVarNames);

    % Convert the table to a numeric matrix    
    data = table2array(currTable);    

    % Calculate VIFs
    currVIFs = VIF(data);

    allVIFs = NaN(1,numVars);    
    varsIdx = ~ismember(varNames, collinearVarNames);
    allVIFs(varsIdx) = currVIFs;

    % Place the VIFs in the columns corresponding to the regressor variable
    % When fewer than all variables are in the 'data' variable, then the
    % missing variables' columns will be NaN.
    
    VIFsMatrix(i,:) = allVIFs;

    % Store the max VIF in a vector for easy interpretation.
    [maxVIF, maxVIFidx] = max(allVIFs,[],2,'omitnan');
    VIFs(i) = maxVIF;

    % If all VIF < threshold for the first time, this is the set of
    % independent variables.
    if maxVIF < cutoff && ~foundIndVarNames
        foundIndVarNames = true;
        indVarNames = varNames(varsIdx);
    elseif ~foundIndVarNames
        % Otherwise, if not yet found independent set,
        % add to the collinear variable names.
        collinearVarNames = [collinearVarNames; varNames(maxVIFidx)];
    end

    % collinearStr = '';
    % for ii = 1:length(collinearVarNames)
    %     collinearStr = [collinearStr collinearVarNames{ii} ', '];
    % end
    % collinearStr = collinearStr(1:end-2);
    if ~foundIndVarNames
        disp(['Max VIF: ' num2str(maxVIF) ' New Collinear Variable: ' varNames{maxVIFidx}]);
    else
        disp(['Independent set already found']);
    end
end