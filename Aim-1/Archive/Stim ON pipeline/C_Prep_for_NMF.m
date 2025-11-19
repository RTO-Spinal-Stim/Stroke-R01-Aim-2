% Input: B_cycles_Struct.mat (cycles_struct), where the cycles were segemented,
% filtered, and normalized
% Output: C_matrixStruct_Cycles.mat, (matrix_struct)
% Places the finalized 0to100 normalized segements in a matrix:


%%
filename = "B_cycles_Struct.mat"; % from B
% Load structure: called cycles_struct
load(fullfile(subject_save_path, filename)) % cycles_struct 

%%
% Places the finalized 0to100 normalized segements in a matrix:

matrix_struct = struct();

walks_list = fieldnames(cycles_struct);
walkDict_modified = cycles_struct.WalksDict;

% In the dictionary - keeping track of outlier and number of steps. 
walkDict_modified.MuscleOrder = cell(height(walkDict_modified), 1);
walkDict_modified.outliersNumbers = cell(height(walkDict_modified), 1);
walkDict_modified.originalAmountSteps = cell(height(walkDict_modified), 1);
walkDict_modified.indices_ofOutliers = cell(height(walkDict_modified), 1);
for wnum =1:length(walks_list)
    WALK_FIELD = walks_list{wnum};
    if isequal(WALK_FIELD,'WalksDict')
        continue; % break?
    end
    walk_number  = str2double(regexp(WALK_FIELD, '\d+', 'match'));
    corres_freq  = cycles_struct.WalksDict(cycles_struct.WalksDict.WalkNum== walk_number, :).Frequency; 
    corres_inter = cycles_struct.WalksDict(cycles_struct.WalksDict.WalkNum== walk_number, :).Intervention; 

    muscle_list = {'RHAM', 'LHAM', 'RVL', 'LVL', 'RRF', 'LRF', 'RTA', 'LTA', 'RMG', 'LMG'};


    averageCyclesMatrix_10muscles = zeros(length(muscle_list), 100); % Preallocate for efficiency
    muscleNames = cell(length(muscle_list), 1);

    averageCyclesMatrix_side1 = zeros(length(muscle_list)/2, 100); % Preallocate for efficiency
    averageCyclesMatrix_side2 = zeros(length(muscle_list)/2, 100); % Preallocate for efficiency
    num_outliers_list = [];
    muscle_reference =strings(0, 1);
    size_list = []; 
    outliers_indices = [];
    
    MATRIX_3D = []; 
    for j = 1: length(muscle_list)
        muscle = muscle_list{j};

        column7Data  = cycles_struct.(WALK_FIELD).(muscle)(:, 7); %(normalized 1x100 of that scycle struct)

        numRows = size(column7Data, 1); % Number of rows
        
        % Initialize a matrix to store the data for averaging
        allSteps = zeros(numRows, 100);
        
        % Convert cell array to a numeric matrix
        for i = 1:numRows
            allSteps(i, :) = column7Data{i}; % Copy each 1x100 array into the matrix
            % ALL STEPS CONTAINS ALL STRIDES FOR THAT SPECIFIC MUSCLE. 
            
        end

        matrix_struct.matrixALL.(WALK_FIELD).(muscle) = allSteps; 
        
        %%% Create the 3D matrix that will contain all strides per muscle
        % check size of arrays because might need to pad:
        
        if j == 1
            MATRIX_3D = cat(3,MATRIX_3D, allSteps);
            % just assign the matrix at first - because is empty
        else
            % now check the size of the next 
            
            
            current_rows_trials = size(MATRIX_3D,1); 
            current_AllSteps_Size = size(allSteps,1); 
            
            
            % Pad MATRIX if needed
            if current_rows_trials < current_AllSteps_Size  % this will only happen if 2nd all steps has more steps than initial 
                if j == 2
                    array1 = MATRIX_3D(:,:); 
                    arraynans = [array1; NaN(current_AllSteps_Size - current_rows_trials, 100)];
                    MATRIX_3D = [];
                    MATRIX_3D = arraynans;
                else
                    disp('there is a problem check - assumption that second muscle is the only one that can change the initial is wrong')
                    % assuming r and left all have same size of trial
                end
                
                allSteps_mod = allSteps;
            end
            
            if current_AllSteps_Size < current_rows_trials
                allSteps_mod = [allSteps; NaN(current_rows_trials - current_AllSteps_Size, 100)];
            end
            
            if current_AllSteps_Size == current_rows_trials
                allSteps_mod = allSteps;
            end



            MATRIX_3D = cat(3,MATRIX_3D, allSteps_mod); % in this case is: # of strides x 100 x (z-axis:muscle)
        end
        % ############
        % CHECK FOR OUTLIERS. 
        %method 1: z scores
%         [outliers,num_outliers] = Outlier_Zscore_Function(allSteps); 
%         % get average 
%         allSteps_noOutliers = allSteps(~outliers, :);
%         
        
        %method 2 - correlations
        [allSteps_noOutliers, num_outliers, outlier_OGindex] = outlierCorrelations(allSteps);
        
        
        % keep track of outliers:
        muscle_reference(end+1) = muscle;
        num_outliers_list(end +1) = num_outliers; 
        size_list(end+1) = size(allSteps,1); 
        outliers_indices = [outliers_indices; outlier_OGindex];
        

        % gets the average without the outliers
        averageCycle = mean(allSteps_noOutliers, 1); % Average along the first dimension

        matrix_struct.AverageCycle.(WALK_FIELD).(muscle) = averageCycle; 
        
        % saving 8 muscles together in a matrix
        averageCyclesMatrix_10muscles(j, :) = averageCycle;
        muscleNames{j} = muscle;
        
        

        
    
    end 
    walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).MuscleOrder         = {muscle_reference};
    walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).outliersNumbers     = {num_outliers_list};
    walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).originalAmountSteps = {size_list};
    % keep track of indices of no-outliers, to be able to drop accross musc
    walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).indices_ofOutliers = {unique(outliers_indices)'};
    
    % Convert string array to character arrays for each muscle name
    muscleNamesChar = cellfun(@char, muscleNames, 'UniformOutput', false);

    matrix_struct.AverageCycle.(WALK_FIELD).AllMusclesAvg               = averageCyclesMatrix_10muscles;
    matrix_struct.AverageCycle.(WALK_FIELD).AllMusclesAvg_MuscleLegend  = muscleNamesChar;

    % Get the right and left separated (for later analysis with paretic vs
    % non paretic)
    
    % Find rows where the muscle name starts with 'R'
    rowsWithR = find(startsWith(muscleNamesChar, 'R'));

    rowsWithL = find(startsWith(muscleNamesChar, 'L'));

    matrix_struct.AverageCycle.(WALK_FIELD).R_MusclesAvg  = averageCyclesMatrix_10muscles(rowsWithR,:);
    matrix_struct.AverageCycle.(WALK_FIELD).L_MusclesAvg  = averageCyclesMatrix_10muscles(rowsWithL,:);
    
    %%%% Add the 3D matrix to have cycles per every stride
    % Permute so the matrix is in form muscles (10) x 100 x stride trial
    stride_trials_muscles3D = permute(MATRIX_3D, [3, 2, 1]); 
    matrix_struct.Trials_perStride.(WALK_FIELD).AllMuscles               = stride_trials_muscles3D;
    matrix_struct.Trials_perStride.(WALK_FIELD).AllMuscles_MuscleLegend  = muscleNamesChar;
    % Get right and left steps:
    matrix_struct.Trials_perStride.(WALK_FIELD).R_Muscles  = stride_trials_muscles3D(rowsWithR,:, :);
    matrix_struct.Trials_perStride.(WALK_FIELD).L_Muscles  = stride_trials_muscles3D(rowsWithL,:, :);
end

matrix_struct.matrixALL.WalksDict = walkDict_modified; 
matrix_struct.AverageCycle.WalksDict = cycles_struct.WalksDict; 



% SAVING

% matrixALL = each row is a cycle 
% AverageCycle = average of all steps for that muscle in that intervention.
%%% - AllMusclesAvg: contains 10 muscles x 100 points (avg of each muscle)
% IndividualCycles = 3D matrix 10 muscles x 100 points (per stride) x #strides

SAVEPATH = fullfile(subject_save_path, "C_matrixStruct_Cycles_noOut.mat");
save(SAVEPATH, "matrix_struct")




%% Sample plotting of muscle modules:
% WALK_FIELD = 'Walk_3';
% averaged_EMG = matrix_struct.AverageCycle.(WALK_FIELD).AllMusclesAvg;
% 
% 
% % Parameters for NMF
% numModules = 4; % Set the number of muscle modules (adjust as needed)
% options = statset('MaxIter', 1000, 'Display', 'final'); % NMF options
% 
% % Perform NMF
% % V = averaged_EMG (input matrix)
% % W = Muscle weightings (10 x numModules)
% % H = Module activations (numModules x 100)
% [W, H] = nnmf(averaged_EMG, numModules, 'algorithm', 'mult', 'options', options);
% 
% % Visualize Results
% figure;
% 
% % Plot W (Muscle Weightings)
% subplot(2, 1, 1);
% bar(W, 'stacked');
% title('Muscle Weightings (W)');
% xlabel('Muscles');
% ylabel('Weight');
% legend(compose('Module %d', 1:numModules), 'Location', 'bestoutside');
% grid on;
% 
% % Plot H (Module Activations)
% subplot(2, 1, 2);
% plot(linspace(0, 100, size(H, 2)), H', 'LineWidth', 2);
% title('Module Activations (H)');
% xlabel('Gait Cycle (% Time)');
% ylabel('Activation');
% legend(compose('Module %d', 1:numModules), 'Location', 'bestoutside');
% grid on;

%% 
% Input: averaged_EMG (m x n matrix where m = number of muscles, n = time points)
% Ensure averaged_EMG is non-negative
WALK_FIELD = 'Walk_1';
averaged_EMG = matrix_struct.AverageCycle.(WALK_FIELD).AllMusclesAvg;

[m, n] = size(averaged_EMG);

% NNMF parameters
maxSynergies = 10; % Maximum number of synergies to test
toleranceFun = 1e-6; % Tolerance for the residual (TolFun)
toleranceX = 1e-4;   % Tolerance for relative change (TolX)
maxRepeats = 300;    % Number of repetitions
vafThresholdTotal = 90; % Overall VAF threshold (%)
vafThresholdMuscle = 75; % Per muscle VAF threshold (%)
vafIncreaseThreshold = 5; % Mean VAF increase threshold (%)

% Initialize storage
bestW = [];
bestH = [];
bestReconstructionError = inf;
bestNumSynergies = 0;

% VAF calculation
computeVAF = @(X, Y) 100 * ((sum(sum(X .* Y))^2) / (sum(sum(X.^2)) * sum(sum(Y.^2))));

% Loop over the number of synergies
for numSynergies = 1:maxSynergies
    bestW_temp = [];
    bestH_temp = [];
    lowestResidual = inf;

    % Repeat NNMF multiple times
    for repeat = 1:maxRepeats
        % Perform NNMF
        options = statset('TolFun', toleranceFun, 'TolX', toleranceX, 'MaxIter', 1000, 'Display', 'off');
        [W, H, residual] = nnmf(averaged_EMG, numSynergies, 'algorithm', 'mult', 'options', options);

        % Keep the best result for the current number of synergies
        if residual < lowestResidual
            bestW_temp = W;
            bestH_temp = H;
            lowestResidual = residual;
        end
    end

    % Reconstruct the EMG signal
    reconstructed_EMG = bestW_temp * bestH_temp;

    % Compute overall VAF
    vafTotal = computeVAF(averaged_EMG, reconstructed_EMG);

    % Compute per-muscle VAF
    vafMuscle = zeros(m, 1);
    for muscleIdx = 1:m
        vafMuscle(muscleIdx) = computeVAF(averaged_EMG(muscleIdx, :), reconstructed_EMG(muscleIdx, :));
    end

    % Check if the criteria are met
    if vafTotal >= vafThresholdTotal && all(vafMuscle >= vafThresholdMuscle)
        % Check if adding more synergies gives less than 5% improvement
        if numSynergies > 1
            meanVAFPrev = mean(vafPerMuscle_prev);
            meanVAFCurr = mean(vafMuscle);
            vafImprovement = meanVAFCurr - meanVAFPrev;

            if vafImprovement < vafIncreaseThreshold
                break; % Stop adding more synergies
            end
        end

        % Update the best results
        bestW = bestW_temp;
        bestH = bestH_temp;
        bestReconstructionError = lowestResidual;
        bestNumSynergies = numSynergies;
    end

    % Store current VAF for comparison in the next iteration
    vafPerMuscle_prev = vafMuscle;
end

% Display results
disp(['Best Number of Synergies: ', num2str(bestNumSynergies)]);
disp(['Reconstruction Error: ', num2str(bestReconstructionError)]);

% Plot results
figure;
subplot(2, 1, 1);
bar(bestW, 'stacked');
title('Muscle Weightings (W)');
xlabel('Muscles');
ylabel('Weight');
legend(compose('Module %d', 1:bestNumSynergies), 'Location', 'bestoutside');
grid on;

subplot(2, 1, 2);
plot(linspace(0, 100, size(bestH, 2)), bestH', 'LineWidth', 2);
title('Module Activations (H)');
xlabel('Gait Cycle (% Time)');
ylabel('Activation');
legend(compose('Module %d', 1:bestNumSynergies), 'Location', 'bestoutside');
grid on;

% Optional: Save results
