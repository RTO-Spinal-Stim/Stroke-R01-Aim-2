function cgam = CGAM(asymmetryIndexMatrix)
% Aria Haver-Hill 7/2022
% Input: Asymmetry matrix with asymmetry indexes
% The matrix should be formated as columns of variables and rows of
% steps/participants
% Output: CGAM vector with CGAM values at each increment
invCovData = inv(cov(asymmetryIndexMatrix));
cgam = diag(sqrt((asymmetryIndexMatrix * invCovData * asymmetryIndexMatrix')/sum(invCovData,"all")));

end