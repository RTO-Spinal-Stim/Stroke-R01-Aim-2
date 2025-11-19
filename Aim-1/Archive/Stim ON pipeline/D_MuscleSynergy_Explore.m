% general code given a table with muscle_Channels (rows) x EMG signal


% Input: C_matrixStruct_Cycles.mat (cycles_struct), where the cycles were segemented,
% filtered, and normalized
% Output: D_synergiesStruct.mat, (matrix_struct)
% Places the finalized 0to100 normalized segements in a matrix:


%%
filename = "C_matrixStruct_Cycles_noOut.mat"; % from C
% Load structure: called matrix_struct
load(fullfile(subject_save_path, filename)) % matrix_struct 

%%
PLOT = false;
PLOTvaf = false;
% WALK_FIELD = 'Walk_8';
side_array = {'L','R'};

walks_list = fieldnames(matrix_struct.AverageCycle);
walkDict_modified = matrix_struct.matrixALL.WalksDict;
% adding columns to table:
walkDict_modified.L_numSynergies    = NaN(height(walkDict_modified), 1);
walkDict_modified.L_VAF             = NaN(height(walkDict_modified), 1);
walkDict_modified.R_numSynergies    = NaN(height(walkDict_modified), 1);
walkDict_modified.R_VAF             = NaN(height(walkDict_modified), 1);

% VAF2
walkDict_modified.L_numSynergiesVAF2     = NaN(height(walkDict_modified), 1);
walkDict_modified.L_VAF2                 = NaN(height(walkDict_modified), 1);
walkDict_modified.R_numSynergiesVAF2     = NaN(height(walkDict_modified), 1);
walkDict_modified.R_VAF2                 = NaN(height(walkDict_modified), 1);

for wnum =1:length(walks_list)
    WALK_FIELD = walks_list{wnum};
    if WALK_FIELD == "WalksDict" 
        continue;
    end
    
    
    for i =1: length(side_array)
        side = side_array{i}+"_MusclesAvg";

        rows_muscle_legend = find(startsWith(matrix_struct.AverageCycle.(WALK_FIELD).AllMusclesAvg_MuscleLegend , side_array{i}));

        averaged_EMG = matrix_struct.AverageCycle.(WALK_FIELD).(side);
        % this contains 1 row for each muscle - 5 rows in total, 100
        % columns



        % Step 1:
        % USE Non-negative matrix factorization: decomposes original averaged_EMG
        % matric into W (muscle activations weights muscles x synergyNum) x H synergy components (synergyNum x length). 

        % choose number of synergies by performing nnmf with various num_synergies:

        % Set the range of synergy numbers you want to test
        max_synergies   = size(averaged_EMG,1); % the number of synergies cannot be greater than the amount of channels/muscles
        VAF             = zeros(1, max_synergies); % To store VAF for each synergy count
        VAF2            = zeros(1, max_synergies); % To store VAF for each synergy count
        
        for num_synergies = 1:max_synergies
            % Perform NMF with 'num_synergies' components
            [W, H] = nnmf(averaged_EMG, num_synergies, 'replicates', 10);

            % Reconstruct the data
            data_approx = W * H;

            % Calculate the total variance of the original data
            total_variance = var(averaged_EMG(:));

            % Calculate the explained variance of the reconstruction
            explained_variance = var(data_approx(:));

            % Compute the VAF for this number of synergies
            % option 1:
            VAF(num_synergies) = (explained_variance / total_variance) * 100;
            % option 2:
            VAF2(num_synergies) = 100*(  1  - sum((averaged_EMG - data_approx).^2, 'all') / sum(averaged_EMG.^2, 'all')  );
        end
        % Plot the VAF for different numbers of synergies
        if PLOTvaf
            figure
            plot(1:max_synergies, VAF, '-o');
            hold on
            plot(1:max_synergies, VAF2, '--o');
            xlabel('Number of Synergies');
            ylabel('VAF (%)');
            title(['VAF vs. Number of Synergies. ',WALK_FIELD , ' ' ,side(1)]);
            grid on;
        end

        % Find index where VAF is >=90, the index is the number of synergies:
        num_synergies = find(VAF >= 90, 1, 'first');
        [W, H] = nnmf(averaged_EMG, num_synergies);
        
        % Saving in matrix_struct:
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).W = W; 
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).H = H;
        
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).NumSynergiesVAF1 = num_synergies;
        
        
        % VAF2:
        num_synergiesVAF2 = find(VAF2 >= 90, 1, 'first');
        [Wvaf2, Hvaf2] = nnmf(averaged_EMG, num_synergiesVAF2);
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).Wvaf2 = Wvaf2; 
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).Hvaf2 = Hvaf2;
        matrix_struct.NMF_results.(side_array{i}).(WALK_FIELD).NumSynergiesVAF2 = num_synergiesVAF2;
        
        % Record number of synergies and VAF
        %matrix_struct.AverageCycle.WalksDict
        
        if side_array{i} == "R"
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).R_numSynergies = num_synergies;
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).R_VAF =  VAF(num_synergies);
           
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).R_numSynergiesVAF2 = num_synergiesVAF2;
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).R_VAF2 =  VAF2(num_synergiesVAF2);
           
           

        elseif side_array{i} == "L"
            
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).L_numSynergies = num_synergies;
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).L_VAF =  VAF(num_synergies);
            
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).L_numSynergiesVAF2 = num_synergiesVAF2;
           walkDict_modified(walkDict_modified.WalkNum == str2double(regexp(WALK_FIELD, '\d+', 'match')), :).L_VAF2 =  VAF2(num_synergiesVAF2);
        end
        
        if PLOT 
            % Plot:
            figure;

            for ii=1:num_synergies
                subplot(num_synergies,2,ii*2-1);
                bar(W(:,ii));
                xticklabels(matrix_struct.AverageCycle.Walk_1.AllMusclesAvg_MuscleLegend(rows_muscle_legend))
                subplot(num_synergies,2,ii*2); 
                plot(H(ii,:));


            end


            sgtitle([WALK_FIELD, ' ' , side]);
        end
    end
end
matrix_struct.WalksDict   = walkDict_modified; 
%% saving:
synergies_struct = matrix_struct; 


SAVEPATH = fullfile(subject_save_path, "D_synergiesStruct.mat");
save(SAVEPATH, "synergies_struct")
