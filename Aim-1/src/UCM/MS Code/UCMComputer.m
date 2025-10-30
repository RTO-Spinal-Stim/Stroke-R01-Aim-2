function[Vucm,Vort,Vtot,DV,DVz] = UCMComputer(data)
%% Description: Receives one set of across-trial finger forces and computes UCM variables at that timepoint.
    % Would be 4 x 15 or 15 x 4 in this study.
% INPUT: Finger forces in m x n (m > n) matrix

data = squeeze(data);

[m,n] = size(data);

% Check if matrix is m > n. If not, changes it.
if m < n
    data = data';
    [m,n] = size(data);
end    

%Calculate each column average
for i = 1:n %Iterate through each column
    c(i) = mean(data(:,i)); %Store mean of one column
end

Averages = [];
Averages = repmat(c,[m 1]);

%"STEP 1" De-mean the data to the origin
NormData = data-Averages;

%"STEP 2" Determine UCM and ORT vectors
g = repmat(1,1,n); % Jacobian
[~,~,d] = svd(g);
o = d(:,1); %Orthogonal
% u = d(:,2:4); %Uncontrolled Manifold 

%"STEP 3" Find length of projections of de-meaned data onto UCM and ORT planes
distORT=NaN(m,1);
distUCM=NaN(m,1);
distTOT=NaN(m,1);
for i=1:m %UCM, ORT, and total projections
    distORT(i) = dot(NormData(i,:),o); % Distance along ORT direction
    distUCM(i) = norm(NormData(i,:)-distORT(i)*o'); %Vector subtraction to determine UCM projection
    distTOT(i) = norm(NormData(i,:));
end

%"STEP 4" Find variances of each

Vucm = sum(diag(distUCM'*distUCM)/(length(distUCM))); % Unadjusted by DOF
Vort = sum(diag(distORT'*distORT)/(length(distORT))); % Unadjusted by DOF
Vtot = sum(diag(distTOT'*distTOT)/(length(distTOT))); % Unadjusted by DOF

% V = var(data(:,1),1) + var(data(:,2),1) + var(data(:,3),1) + var(data(:,4),1);
% Vnorm = var(NormData(:,1),1) + var(NormData(:,2),1) + var(NormData(:,3),1) + var(NormData(:,4),1);

%"STEP 5" Calculate DV
DV = (Vucm/(n-1)-Vort/(n-(n-1)))/(Vtot/n);

% STEP 6: Compute DVz
DVz = 0.5*log(((n+DV)/(n/(n-1)-DV)));

% -------- Different DV computation.
% Dv=Vucm/((n-1)*Vort);
% 
% logDv=log10(Dv);

end