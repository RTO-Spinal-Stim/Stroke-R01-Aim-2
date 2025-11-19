function [r2] = untitled()
p = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\unmatchedCycles.csv";
T = readtable(p);

x = T.StepLengths_GR;
y = T.KNEE_JointAngles_Max;
x_mean = x - mean(x);
y_mean = y - mean(y);

% r2 = computeR2(x, y);
r2 = computeR2(x_mean, y_mean);
scatter(x_mean, y_mean);
end

function R2 = computeR2(X, Y)
    % Compute R-squared between X and Y vectors
    % 
    % Inputs:
    %   X - Predictor/independent variable vector
    %   Y - Response/dependent variable vector
    %
    % Output:
    %   R2 - Coefficient of determination (R-squared)
    
    % Ensure inputs are column vectors
    X = X(:);
    Y = Y(:);
    
    % Fit linear regression model: Y ~ b0 + b1*X
    n = length(X);
    X_with_intercept = [ones(n, 1), X];
    b = X_with_intercept \ Y;  % Regression coefficients [b0; b1]
    
    % Calculate predicted values
    Y_pred = X_with_intercept * b;
    
    % Calculate mean of observed values
    Y_mean = mean(Y);
    
    % Calculate total sum of squares
    SS_total = sum((Y - Y_mean).^2);
    
    % Calculate residual sum of squares
    SS_residual = sum((Y - Y_pred).^2);
    
    % Calculate R-squared
    R2 = 1 - (SS_residual / SS_total);
end