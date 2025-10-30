function [UCMProj, ORTProj] = ProjectionComputer(data)
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
g = repmat(1,1,n);
[~,~,d] = svd(g);
o = d(:,1); %Orthogonal
u = d(:,2:4); %Uncontrolled Manifold 

%"STEP 3" Find length of projections of de-meaned data onto UCM and ORT planes

for i=1:m %UCM, ORT, and total projections
    distORT(i) = dot(NormData(i,:),o); % Distance along ORT direction
    distUCMdir1(i) = dot(NormData(i,:),u(1:4,1));
    distUCMdir2(i) = dot(NormData(i,:),u(1:4,2));
    distUCMdir3(i) = dot(NormData(i,:),u(1:4,3));
    distTOT(i) = norm(NormData(i,:));
end

%"STEP 4" Find vector coordinates of de-meaned projected data point onto UCM

for i = 1:m
    ORTProj(i,1:n) = o*distORT(i);
    UCMDir1(i,1:n) = u(1:4,1)*distUCMdir1(i);
    UCMDir2(i,1:n) = u(1:4,2)*distUCMdir2(i);
    UCMDir3(i,1:n) = u(1:4,3)*distUCMdir3(i);
    UCMProj(i,1:n) = UCMDir1(i,:) + UCMDir2(i,:) + UCMDir3(i,:);
end

ORTProj = ORTProj + Averages;
UCMProj = UCMProj + Averages;