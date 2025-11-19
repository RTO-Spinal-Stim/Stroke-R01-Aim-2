function [noOutlier_data, num_outliers, outlier_OGindex] = outlierCorrelations(allSteps)
% usually receives all steps. 

% Assume you have a cell array `timeSignals` containing x time signals
% Each element of `timeSignals` is a vector representing a time signal.

correlations = corr(allSteps'); % Transpose for each column to be a signal
meanCorr = mean(correlations - eye(size(correlations)), 2);
threshold = mean(meanCorr) - 2 * std(meanCorr);
outliers = find(meanCorr < threshold);
% disp('Outlier indices:');
% disp(outliers);

num_outliers = length(outliers);
noOutlier_data = allSteps;
noOutlier_data(outliers, :) = [];

outlier_OGindex = outliers;
%plot outliers:
% figure
% out_sign = allSteps(outliers, :);
% for i =1:size(out_sign,1)
%     plot(out_sign(i,:))
%     hold on
% end
% 
% 
% for i =1:size(noOutlier_data,1)
%     plot(noOutlier_data(i,:), 'black')
%     hold on
% end

end


%%
% Old outlier z score function:

