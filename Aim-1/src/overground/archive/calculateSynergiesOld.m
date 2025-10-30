function avgSynergies = calculateSynergiesOld(accumulatedEMG)

%% PURPOSE: CALCULATE THE AVERAGE NUMBER OF MUSCLE SYNERGIES

% Define the number of synergies
numSynergies = 6; % Adjust this number as needed

left = accumulatedEMG.left;
right = accumulatedEMG.right;

numTrials = size(left.HAM,1);


for m = 1:numTrials
    
    % Concatenate left and right cycle data for all muscles
    allCycles = [left.HAM(m,:);left.RF(m,:);left.MG(m,:);left.TA(m,:);left.VL(m,:); ...
        right.HAM(m,:);right.RF(m,:);right.MG(m,:);right.TA(m,:);right.VL(m,:)];
    
    % Perform Non-negative Matrix Factorization (NMF) to extract synergies and weights
    [W, H] = nnmf(allCycles, numSynergies);
    
    % Output the muscle synergies and their corresponding weights
    synergies = W;
    weights = H;
    
    % Define muscle names
    muscleNames = {'LHAM', 'LRF', 'LMG', 'LTA','LVL', 'RHAM', 'RRF', 'RMG', 'RTA', 'RVL'};
    
    % Calculate Variance Accounted For (VAF) and plot in a separate figure
    VAF_values = [];
    for nSynergies = 1:6 % Example range
        [W_temp, H_temp] = nnmf(allCycles, nSynergies);
        reconstruction = W_temp * H_temp;
        VAF = 1 - sum((allCycles - reconstruction).^2, 'all') / sum(allCycles.^2, 'all');
        VAF_values = [VAF_values, VAF];
    end
    
    VAF_thresh = 0.9;
    counter = 1;
    
    for i = 1:numel(muscleNames)
        
        if VAF_values(i) >= VAF_thresh
            synergiesNeeded(m) = counter;
            break;
        else
            counter = counter + 1;
        end
        
    end
    
    avgSynergies = mean(synergiesNeeded);
    
end


%
%     % Plot the VAF values in a separate figure
%     figure;
%     plot(1:6, VAF_values, '-o');
%     title('Variance Accounted For (VAF)');
%     xlabel('Number of Synergies');
%     ylabel('VAF');
%
%     % Create a new figure for synergies and activation coefficients
%     figure;
%     for i = 1:numSynergies
%         % Plot weight vectors for each synergy
%         subplot(numSynergies, 2, 2*i-1);
%         bar(W(:,i));
%         set(gca, 'xticklabel', muscleNames);
%         title(['Synergy ', num2str(i), ' Weights']);
%         xlabel('Muscles');
%         ylabel('Weights');
%
%         % Plot activation coefficients for each synergy
%         subplot(numSynergies, 2, 2*i);
%         plot(H(i,:));
%         title(['Synergy ', num2str(i), ' Activation']);
%         xlabel('Percentage of gait cycle (%)');
%         ylabel('Activation');
%     end
%
%     % Adjust layout to prevent subplot overlap
%     set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);