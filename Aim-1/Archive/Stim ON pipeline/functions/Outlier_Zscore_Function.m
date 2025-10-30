% allSteps in a num signals x 100 dataset 
% idea is to remove any signal that may be an outlier:

% WALK_FIELD = 'Walk_1';
% muscle = 'RTA';
% allSteps = matrix_struct.matrixALL.(WALK_FIELD).(muscle);

function [outliers,num_outliers] = Outlier_Zscore_Function(allSteps)

    mean_signal = mean(allSteps,1);
    std_signal = std(allSteps, 0, 1);  % Standard deviation at each point

    % Compute Z-scores for each signal - same size as allSteps
    z_scores = (allSteps - mean_signal) ./ std_signal;

    % Define a threshold (e.g., ±2)
    threshold = 5;


    % Identify outlier signals (any signal exceeding the threshold at any point)
    outliers = any(abs(z_scores) > threshold, 2);
    %fprintf('Excluded %d outlier signals.\n', sum(outliers));
    num_outliers = sum(outliers);
    filtered_data = allSteps(~outliers, :);
    % plot outliers:
%     figure
%     out_sign = allSteps(outliers, :);
%     for i =1:size(out_sign,1)
%         plot(out_sign(i,:))
%         hold on
%     end
% 
% 
%     for i =1:size(filtered_data,1)
%         plot(filtered_data(i,:), 'black')
%         hold on
%     end
end