function [formula] = symmetryFormulae(formulaNum)

%% PURPOSE: LIST ALL OF THE SYMMETRY FORMULAE
% Inputs:
% formulaNum: Scalar double used to select a specific formula
%
% Outputs:
% formula: An anonymous function handle
%
% Formulae:
% 1: Previously used symmetry equation: 2|x2-x1|/(x2+x1)
% 2: Modification [0, 1] of previous equation: -1 * ( |x2-x1|/(x2+x1) ) + 1
% 3: Split-belt literature symmetry equation: (x2-x1)/(x1+x2)
% 4: Equation from the grant: 100 * (1-abs(1-x1/x2))
% 5: Simple ratio: x1/x2
% 6: The same formula as #1, but multiplied by 100

switch formulaNum
    case 1
        formula = @(x1, x2) 2*abs(x2-x1) / (x2 + x1);
    case 2
        formula = @(x1, x2) -1*( abs(x2-x1)/(x2 + x1) ) + 1;
    case 3
        formula = @(x1, x2) (x2-x1) / (x1 + x2);
    case 4
        formula = @(x1, x2) 100 * (1-abs(1-x1/x2));
    case 5
        formula = @(x1, x2) x1/x2;  
    case 6
        formula = @(x1, x2) 100 * ( 2*abs(x2-x1) / (x2 + x1) );
    otherwise
        error('Wrong formulaNum entered!');
end