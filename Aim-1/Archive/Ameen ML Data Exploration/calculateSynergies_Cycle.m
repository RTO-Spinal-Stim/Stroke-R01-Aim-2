function nSynergiesRequired = calculateSynergies_Cycle(leftMuscles, rightMuscles)
    maxSynergies = 6;
    VAF_thresh = 0.9;
    VAF = 0;
    nSynergiesRequired = maxSynergies;

    % Concatenate left and right muscle data
    allCycles = [leftMuscles; rightMuscles];
    
    for nSynergies = 1:maxSynergies
        [W_temp, H_temp] = nnmf(allCycles, nSynergies);
        reconstruction = W_temp * H_temp;
        VAF = 1 - sum((allCycles - reconstruction).^2, 'all') / sum(allCycles.^2, 'all');
        
        if VAF >= VAF_thresh
            nSynergiesRequired = nSynergies;
            break;
        end
    end
end
