rng default
clear all
clc
a = rand(15,2);
[m,n] = size(a);

%j = filt(a)

%Calculate each column average
for i = 1:n %Iterate through each column
    c(i) = mean(a(:,i)); %Store one column
end

Averages = [];
Averages = repmat(c,[m 1]);

%"STEP 1" De-mean the data to the origin
NormData = a-Averages;

%"STEP 2" Determine UCM and ORT vectors
m = repmat(1,1,n);
[~,~,d] = svd(m);
o = d(:,1); %Orthogonal
% u = d(:,2:4); %Uncontrolled Manifold 

%"STEP 3" Find projections of de-meaned data onto UCM and ORT planes
distUCM = [];
distORT = [];
for i=1:m 
    distORT(i) = dot(NormData(i,:),o);
    distUCM(i) = norm(NormData(i,:)-distORT(i)*o'); %Vector subtraction to determine UCM projection
    distTOT(i) = norm(NormData(i,:));
end

%"STEP 4" Find variances of each
% %VarTOT = VarUCM + VarORT;

%BASIS VECTORS??
%Why length(distUCM)-1? Why minus one? Why isn't UCM/3 here
VarUCM = sum(diag(distUCM'*distUCM)/(length(distUCM)));
VarORT = sum(diag(distORT'*distORT)/(length(distORT)));
VarTOT = sum(diag(distTOT'*distTOT)/(length(distTOT)));

VarTOT- VarUCM-VarORT
% VarTOTCheck = var(Distances); %What was the alternative method for checking VarTOT?

%"STEP 5" Calculate DV
%DV = (VarUCM-VarORT)/VarTOT;
DV = (VarUCM/(n-1)-VarORT)/(VarTOT/n);
disp(DV)

% figure; hold on
% plot(a(:,1),a(:,2),'o','MarkerFaceColor','r')
% axis equal
% plot(NormData(:,1),NormData(:,2),'o','MarkerFaceColor','g')