% Set parameters
n = 1000; % Number of samples
target_mean_1 = 5; % Desired mean 1
target_mean_2 = 20; % Desired mean 2
target_std_1 = 5; % Desired standard deviation 1
target_std_2 = 2; % Desired standard deviation 2

% Method 1: Two different normal distributions with same parameters
dist1x = normrnd(target_mean_1, target_std_1, n, 1);
dist1y = normrnd(target_mean_1, target_std_1, n, 1);
dist2x = normrnd(target_mean_2, target_std_2, n, 1);
dist2y = normrnd(target_mean_2, target_std_2, n, 1);

% Plot the data distributions
Q = figure;
ax1 = subplot(1,3,1);
scatter(dist1x, dist1y, 'r','o');
hold on;
scatter(dist2x, dist2y, 'g','sq');
title('Original Data Distributions');
xlabel('X values');
ylabel('Y values');
legend({'Int 1', 'Int 2'});
axis equal;

% Calculate CGAM with distributions separately
cgam1 = CGAM([dist1x dist1y]);
cgam2 = CGAM([dist2x dist2y]);

% Calculate CGAM with distributions together
dist = [dist1x dist1y; dist2x dist2y];
cgam = CGAM(dist);

% Plot same x,y data but colored by CGAM values
ax2 = subplot(1,3,2);
hold on;
% Combine x and y coordinates
all_x = [dist1x; dist2x];
all_y = [dist1y; dist2y];

% Use the combined cgam values for coloring
scatter(dist1x, dist1y, 36, cgam1, 'o');
scatter(dist2x, dist2y, 36, cgam2, 'sq');
colorbar;
colormap(jet); % You can change this to other colormaps like 'hot', 'cool', 'parula', etc.
title('CGAM Computed Separately');
xlabel('X values');
ylabel('Y values');
clim([min(cgam) max(cgam)]); % Set color axis limits
axis equal;
legend({'Int 1', 'Int 2'});

% Plot all
ax3 = subplot(1,3,3);
scatter(all_x, all_y, 36, cgam);
colorbar;
colormap(jet); % You can change this to other colormaps like 'hot', 'cool', 'parula', etc.
title('CGAM Computed Together');
xlabel('X values');
ylabel('Y values');
clim([min(cgam) max(cgam)]); % Set color axis limits
axis equal;
legend({'All Together'});