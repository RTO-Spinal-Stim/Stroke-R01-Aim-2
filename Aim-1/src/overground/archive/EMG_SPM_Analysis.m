 function results = EMG_SPM_Analysis(accumulatedEMG)
    fields = fieldnames(accumulatedEMG);
    results = struct; % Initialize a struct to store the results
    
    for i = 1:length(fields)
        field = fields{i};
        YA = accumulatedEMG.right.(field);
        YB = accumulatedEMG.left.(field);
        
        % Conduct SPM analysis
        spm = spm1d.stats.ttest2(YA, YB);
        spmi = spm.inference(0.05, 'two_tailed', true, 'interp',true);
        
        % Adjust endpoints storage
        if isempty(spmi.clusters)
            results.(field).endpoints = [0 0]; % Save as [0 0] if no clusters
        else
            endpoints = arrayfun(@(x) x.endpoints, spmi.clusters, 'UniformOutput', false);
            endpoints = cell2mat(endpoints'); % Convert cell array to matrix
            if isempty(endpoints)
                results.(field).endpoints = [0 0]; % Save as [0 0] if endpoints are empty
            else
                results.(field).endpoints = reshape(endpoints, [], 2); % Reshape to n x 2
            end
        end
        
        % Plotting code remains unchanged...
    end



        
        % Plotting
     
        figure('position', [0 0 1000 300])
        
        % Plot mean and SD
        subplot(121)
        spm1d.plot.plot_meanSD(YA, 'color', 'k');
        hold on
        spm1d.plot.plot_meanSD(YB, 'color', 'r');
        title(['Mean and SD (' field ')'])
        
        % Plot SPM results
        subplot(122)
%         if isfield(spmi, 'plot')
            spmi.plot();
            spmi.plot_threshold_label();
            spmi.plot_p_values();
            title(['Hypothesis test (' field ')'])
%         else
            title(['No significant clusters (' field ')'])
%         end
    end

