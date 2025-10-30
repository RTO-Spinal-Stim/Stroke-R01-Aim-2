function [VIF] = VIF(Data)
% Sarah Kettlety 2025
% Inputs:
% Data: Each column is one variable, rows are observations
%
% Outputs:
% VIF: Vector of VIFs in the same order as the columns in Data

VIF = diag(inv(corrcoef(Data)));

end