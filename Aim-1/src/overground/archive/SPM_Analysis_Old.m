function results = SPM_Analysis_Old(input)

%% PURPOSE: PERFORM STATISTICAL PARAMETRIC MAPPING (SPM)

fields = fieldnames(input.right);
results = struct; % Initialize a struct to store the results

for i = 1:length(fields)
    field = fields{i};
    YA = input.right.(field);
    YB = input.left.(field);
    
    % Conduct SPM analysis
    spm = spm1d.stats.ttest2(YA, YB);
    spmi = spm.inference(0.05, 'two_tailed', true, 'interp',true);
    
    % Check if clusters exist
    if isempty(spmi.clusters)
        results.(field).endpoints = [0 0]; % No clusters, so store an empty array
    else
        % Initialize an array to store endpoints for each cluster
        cluster_endpoints = zeros(length(spmi.clusters), 2);
        for j = 1:length(spmi.clusters)
            
            cluster_endpoints(j,:) = spmi.clusters{j}.endpoints;
            
        end
        results.(field).endpoints = cluster_endpoints; % Store the endpoints array in the results
    end
    
    %     % Plotting
    %     figure('position', [0 0 1000 300])
    %
    %     % Plot mean and SD
    %     subplot(121)
    %     spm1d.plot.plot_meanSD(YA, 'color', 'k');
    %     hold on
    %     spm1d.plot.plot_meanSD(YB, 'color', 'r');
    %     title(['Mean and SD (' field ')'])
    %
    %     % Plot SPM results
    %     subplot(122)
    %
    %     spmi.plot();
    %     spmi.plot_threshold_label();
    %     spmi.plot_p_values();
    %     title(['Hypothesis test (' field ')'])
    
    
end
