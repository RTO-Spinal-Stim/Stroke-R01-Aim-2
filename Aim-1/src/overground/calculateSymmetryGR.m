function [symmetryValues] = calculateSymmetryGR(values, lrIdx, startIdxNum, endIdx, formulaNum)

%% PURPOSE: CALCULATE THE SYMMETRY VALUES FOR ONE TRIAL OF GAITRITE DATA.
% Inputs:
% values: The L/R values to compute symmetry for
% lrIdx: Logical vector indicating L vs. R values
% startIdxNum: The index to start processing at
% endIdx: The index to end processing at (negative value)
% formulaNum: Scalar double to select the formula
%
% Outputs:
% symmetryValues: Vector of symmetry values
%
% NOTE: The first input to the symmetry formula is always the L value, the second
% input is always the R value. Conversion to paretic/non-paretic or 
% dominant/non-dominant can take place later if needed

% Data checks
if endIdx > 0
    error('endIdx must be a negative number or zero');
end

assert(length(values) == length(lrIdx));

% Select the formula to use
formula = symmetryFormulae(formulaNum);

% Define the end index value
endIdxNum = length(lrIdx) + endIdx;

% Compute the symmetry values
symmetryValues = NaN(1,endIdxNum-startIdxNum+1);
for i = startIdxNum:endIdxNum
    if lrIdx(i) == 1 % Current value is L
        valueL = values(i);
        valueR = values(i+1);
    elseif lrIdx(i) == 0 % Current value is R
        valueL = values(i+1);
        valueR = values(i);
    end
    symmetryValues(i-startIdxNum+1) = formula(valueL, valueR);
end