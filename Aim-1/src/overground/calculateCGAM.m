function [tableOut, matrixStatsTable] = calculateCGAM(tableIn, indVars, catVars)

%% PURPOSE: CALCULATE CGAM FOR ALL ROWS OF THE TABLE
% Inputs:
% tableIn: The input data table
% indVars: Cell array of independent variable names
% catVars: Cell array of the categorical variables to group data by when computing CGAM
%
% Outputs:
% tableOut: Output data table with CGAM data

tableOut = copyCategorical(tableIn);

% catVars = {'Subject'};
% catVars = {'Subject', 'Speed'};
% catVars = {'Subject','Intervention'};
% catVars = {'Subject', 'Intervention', 'PrePost'};
catVars = {'Subject', 'Intervention', 'PrePost', 'Speed'};

tableInIndep = tableIn(:, indVars);
uniqueTrials = unique(tableOut(:,catVars),'rows','stable');
matrixStatsTable = uniqueTrials;
for i=1:height(uniqueTrials)
    currNameRowsIdx = tableContains(tableIn, uniqueTrials(i,:));
    currRows = tableInIndep(currNameRowsIdx,:);
    currData = table2array(currRows);
    [residual, c] = test_pseudoinverse_accuracy(cov(currData));
    matrixStatsTable.Residual(i) = residual;
    matrixStatsTable.Condition(i) = c;
    cgam = CGAM(currData);
    tableOut.CGAM(currNameRowsIdx) = cgam;    
end

end

function [residual, c] = test_pseudoinverse_accuracy(A)
    % Calculate the pseudoinverse
    A_pinv = pinv(A);
    
    % Calculate the residual norm ||A·A⁺·A - A||. Closer to zero is better
    residual = norm(A * A_pinv * A - A, 'fro');
    
    % Calculate relative error for better interpretation
    relative_residual = residual / norm(A, 'fro');
    
    % Display results
    fprintf('Absolute residual norm: %e\n', residual);
    fprintf('Relative residual norm: %e\n', relative_residual);
    
    % Provide interpretation
    disp(['Residual: ' num2str(residual) ' Relative Residual: ' num2str(relative_residual)]);
    if relative_residual < 1e-12
        fprintf('Excellent accuracy: residual is close to machine precision.\n');
    elseif relative_residual < 1e-8
        fprintf('Good accuracy: residual is sufficiently small.\n');
    elseif relative_residual < 1e-4
        fprintf('Moderate accuracy: some numerical issues may be present.\n');
    else
        fprintf('Poor accuracy: significant numerical errors detected.\n');
    end

    c = cond(A);

    disp(['Condition: ' num2str(c)]);

    if c > 10^10
        disp('Severely ill-conditioned');
    elseif c > 10^6
        disp('Definitely ill-conditioned');
    elseif c > 10^4
        disp('Starting to be ill-conditioned');
    else
        disp('Not ill-conditioned');
    end
end
    