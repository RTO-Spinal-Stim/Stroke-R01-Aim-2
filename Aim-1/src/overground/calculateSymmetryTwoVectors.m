function [symmValues] = calculateSymmetryTwoVectors(v1, v2, formulaNum)

%% PURPOSE: CALCULATE THE SYMMETRY OF TWO VECTORS
% Inputs:
% v1: The first vector of data
% v2: The second vector of data
% formulaNum: A number specifying which symmetry formula to use in
% calculation
%
% Outputs:
% symmValues: The vector of symmetry values.
%
% Formulae:
% 1: Previously used symmetry equation: 2|x2-x1|/(x2+x1)
% 2: Modification [0, 1] of previous equation: -1 * ( |x2-x1|/(x2+x1) ) + 1
% 3: Split-belt literature symmetry equation: (x2-x1)/(x1+x2)
% 4: Equation from the grant: 100 * (1-abs(1-x1/x2))
% 5: Simple ratio: x1/x2
%
% For additional details, see here: "Y:\LabMembers\MTillman\Scientific Notebook\25.02.19 Range of Symmetry Values.pdf"

if iscell(v1)
    v1 = v1{1};
end

if iscell(v2)
    v2 = v2{1};
end

if length(v1) ~= length(v2)
    error('The two data vectors are not the same length!');
end

if ~exist('formulaNum','var')
    %formulaNum = 2;
    formulaNum = 1;
end

% Get the specified symmetry formula
formula = symmetryFormulae(formulaNum);

symmValues = NaN(size(v1)); % Initialize the symmetry values vector

for i = 1:length(v1)
    item1 = v1(i);
    item2 = v2(i);
    % Handle NaN
    if isnan(item1) || isnan(item2)
        symmValues(i) = NaN;
        continue;
    end
    symmValues(i) = formula(item1, item2);
end