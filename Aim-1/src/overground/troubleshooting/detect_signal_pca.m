function [signal_rows, results] = detect_signal_pca(data, varargin)
% DETECT_SIGNAL_PCA - Identify time series containing signal using PCA
%
% Inputs:
%   data - 70x200 matrix (rows = time series, columns = time points)
%   Optional name-value pairs:
%     'threshold' - Loading threshold for signal detection (default: auto)
%     'num_components' - Number of PCs to analyze (default: 3)
%     'plot_results' - Whether to create diagnostic plots (default: true)
%
% Outputs:
%   signal_rows - Logical vector indicating which rows contain signal
%   results - Struct with detailed analysis results

% Parse inputs
p = inputParser;
addRequired(p, 'data', @(x) ismatrix(x) && size(x,1)==70 && size(x,2)==200);
addParameter(p, 'threshold', [], @isnumeric);
addParameter(p, 'num_components', 3, @isnumeric);
addParameter(p, 'plot_results', true, @islogical);
parse(p, data, varargin{:});

% Extract parameters
threshold = p.Results.threshold;
num_components = p.Results.num_components;
plot_results = p.Results.plot_results;

fprintf('Performing PCA analysis on %dx%d time series data...\n', size(data));

%% Step 1: Prepare data and perform PCA
% For PCA, we want:
% - Rows = observations (time points) = 200
% - Columns = variables (time series) = 70
% So we transpose our 70x200 data to 200x70

data_transposed = data'; % Now 200x70 (time points x time series)

% Center each time series (subtract mean across time for each series)
data_centered = data_transposed - mean(data_transposed, 1);

% Perform PCA
[coeff, score, latent, ~, explained] = pca(data_centered);

% Now the dimensions are correct:
% coeff: Principal component coefficients (70 x num_components) - loadings for each time series
% score: Principal component scores (200 x num_components) - PC values at each time point
% latent: Eigenvalues
% explained: Percentage of variance explained

%% Step 2: Analyze loadings to identify signal-containing series
% The coeff matrix contains the loadings for each time series on each PC
% coeff is 70 x num_components (each row corresponds to one time series)
pc_loadings = coeff(:, 1:num_components);

% Focus on first PC (captures most variance)
pc1_loadings = abs(pc_loadings(:, 1));

%% Step 3: Determine threshold for signal detection
if isempty(threshold)
    % Automatic threshold using multiple methods
    
    % Method 1: Otsu's method (optimal threshold for bimodal distribution)
    try
        threshold_otsu = graythresh(pc1_loadings) * max(pc1_loadings);
    catch
        threshold_otsu = mean(pc1_loadings) + std(pc1_loadings);
    end
    
    % Method 2: Mean + 2*std (statistical outlier detection)
    threshold_stats = mean(pc1_loadings) + 2*std(pc1_loadings);
    
    % Method 3: Knee point detection (elbow method)
    [sorted_loadings, sort_idx] = sort(pc1_loadings, 'descend');
    diffs = diff(sorted_loadings);
    [~, knee_idx] = max(abs(diff(diffs))); % Find maximum curvature
    threshold_knee = sorted_loadings(knee_idx + 1);
    
    % Choose the most conservative threshold
    threshold = min([threshold_otsu, threshold_stats, threshold_knee]);
    
    fprintf('Auto-selected thresholds:\n');
    fprintf('  Otsu method: %.4f\n', threshold_otsu);
    fprintf('  Statistical (μ+2σ): %.4f\n', threshold_stats);
    fprintf('  Knee point: %.4f\n', threshold_knee);
    fprintf('  Selected threshold: %.4f\n', threshold);
end

%% Step 4: Identify signal-containing rows
threshold = 0.165;
signal_rows = pc1_loadings > threshold;
num_signal_rows = sum(signal_rows);

fprintf('\nResults:\n');
fprintf('  PC1 explains %.1f%% of variance\n', explained(1));
fprintf('  Identified %d/%d time series as containing signal\n', num_signal_rows, 70);
fprintf('  Signal row indices: %s\n', mat2str(find(signal_rows)'));

%% Step 5: Quality metrics
% Compute reconstruction quality for each time series using first few PCs
% Reconstruct in the original space: score * coeff'
reconstructed_transposed = score(:, 1:num_components) * coeff(:, 1:num_components)';
reconstructed = reconstructed_transposed'; % Back to 70x200

% Calculate reconstruction error for each time series
reconstruction_error = sqrt(mean((data - (reconstructed + mean(data, 2))).^2, 2));

% Correlation with first PC pattern (first PC loadings represent the signal pattern)
pc1_pattern = coeff(:, 1); % First PC loadings (70x1)
correlations = zeros(70, 1);
for i = 1:70
    % Correlate each time series with the PC1 loading pattern
    correlations(i) = abs(pc1_pattern(i)); % This is just the absolute loading
end

%% Step 6: Store results
results = struct();
results.pc_loadings = pc_loadings;
results.pc1_loadings = pc1_loadings;
results.threshold = threshold;
results.explained_variance = explained;
results.reconstruction_error = reconstruction_error;
results.correlations_with_pc1 = correlations;
results.signal_indices = find(signal_rows);
results.coeff = coeff;
results.score = score;

%% Step 7: Create diagnostic plots
if plot_results
    create_diagnostic_plots(data, signal_rows, results);
end

end

function create_diagnostic_plots(data, signal_rows, results)
% Create comprehensive diagnostic plots

figure('Position', [100, 100, 1200, 800]);

% Plot 1: PC1 loadings with threshold
subplot(2, 3, 1);
bar(results.pc1_loadings);
hold on;
yline(results.threshold, 'r--', 'LineWidth', 2);
xlabel('Time Series Index');
ylabel('|PC1 Loading|');
title('PC1 Loadings (Signal Detection)');
legend('Loadings', 'Threshold', 'Location', 'best');
grid on;

% Plot 2: Scree plot (explained variance)
subplot(2, 3, 2);
plot(1:min(10, length(results.explained_variance)), ...
     results.explained_variance(1:min(10, end)), 'bo-', 'LineWidth', 2);
xlabel('Principal Component');
ylabel('Variance Explained (%)');
title('Scree Plot');
grid on;

% Plot 3: First few time series (signal vs noise)
subplot(2, 3, 3);
signal_indices = results.signal_indices;
noise_indices = find(~signal_rows);

% Plot a few examples of each
plot_signal = signal_indices(1:min(3, length(signal_indices)));
plot_noise = noise_indices(1:min(3, length(noise_indices)));

hold on;
for i = plot_signal
    plot(data(i, :), 'LineWidth', 2);
end
for i = plot_noise
    plot(data(i, :), '--', 'LineWidth', 1);
end
xlabel('Time Point');
ylabel('Amplitude');
title('Example Time Series');
% legend([arrayfun(@(x) sprintf('Signal %d', x), plot_signal, 'UniformOutput', false), ...
%         arrayfun(@(x) sprintf('Noise %d', x), plot_noise, 'UniformOutput', false)], ...
%        'Location', 'best');
grid on;

% Plot 4: PC1 vs PC2 scatter
subplot(2, 3, 4);
scatter(results.pc_loadings(~signal_rows, 1), results.pc_loadings(~signal_rows, 2), ...
        50, 'r', 'filled');
hold on;
scatter(results.pc_loadings(signal_rows, 1), results.pc_loadings(signal_rows, 2), ...
        50, 'b', 'filled');
xlabel('PC1 Loading');
ylabel('PC2 Loading');
title('PC1 vs PC2 Loadings');
legend('Noise', 'Signal', 'Location', 'best');
grid on;

% Plot 5: Reconstruction error
% subplot(2, 3, 5);
% boxplot([results.reconstruction_error(~signal_rows), results.reconstruction_error(signal_rows)], ...
%         [zeros(sum(~signal_rows), 1); ones(sum(signal_rows), 1)], ...
%         'Labels', {'Noise', 'Signal'});
% ylabel('Reconstruction Error');
% title('Reconstruction Quality');
% grid on;

% Plot 6: Average signal pattern
subplot(2, 3, 6);
if sum(signal_rows) > 0
    avg_signal = mean(data(signal_rows, :), 1);
    avg_noise = mean(data(~signal_rows, :), 1);
    
    plot(avg_signal, 'b-', 'LineWidth', 2);
    hold on;
    plot(avg_noise, 'r--', 'LineWidth', 2);
    xlabel('Time Point');
    ylabel('Average Amplitude');
    title('Average Patterns');
    legend('Signal Average', 'Noise Average', 'Location', 'best');
    grid on;
end

sgtitle('PCA Signal Detection Analysis', 'FontSize', 14, 'FontWeight', 'bold');
end

% Example usage:
% Assuming your data is in a variable called 'timeseries_data' (70x200)
% [signal_rows, results] = detect_signal_pca(timeseries_data);
% 
% To use custom threshold:
% [signal_rows, results] = detect_signal_pca(timeseries_data, 'threshold', 0.1);
%
% To suppress plots:
% [signal_rows, results] = detect_signal_pca(timeseries_data, 'plot_results', false);