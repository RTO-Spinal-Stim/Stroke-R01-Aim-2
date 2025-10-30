function [averagedEMG, accumulatedEMG] = downSampleAveragedEMG(filteredEMG, processedGait, muscles)

emgTrials = fieldnames(filteredEMG);
gaitTrials = fieldnames(processedGait);

% Initialize the accumulated EMG cycles
for i=1:length(muscles)
    accumulatedEMG.left.(muscles{i}) = [];
    accumulatedEMG.right.(muscles{i}) = [];
end

for i = 1:numel(gaitTrials)
    
    trialEMG = emgTrials{i};
    trialGait = gaitTrials{i};
    
    EMGall = filteredEMG.(trialEMG);
    muscle = fieldnames(EMGall);
    
    % Seperate left/right muscles
    for h = 1:numel(muscles)
        EMG.left.(muscles{h}) = EMGall.(muscle{h+5});
        EMG.right.(muscles{h}) = EMGall.(muscle{h});
    end
    
    gait = processedGait.(trialGait);
    
    for j = 1:numel(muscles)
        
        EMGleft = EMG.left.(muscles{j});
        EMGright = EMG.right.(muscles{j});
        
        if length(gait.leftStanceEMG) > length(gait.rightStanceEMG)
            cycle = length(gait.rightStanceEMG(:,1));
        else
            cycle = length(gait.leftStanceEMG(:,1));
        end
        
        leftEmgCycle = zeros(cycle,101);
        rightEmgCycle = zeros(cycle,101);
        
        for k = 1:cycle
            
            % Get EMG of Stance - Swing Phase
            currentLeft = EMGleft(gait.leftStanceEMG(k,1):gait.leftSwingEMG(k,2));
            currentRight = EMGright(gait.rightStanceEMG(k,1):gait.rightSwingEMG(k,2));
            
            numLeftSamples = length(currentLeft);
            numRightSamples = length(currentRight);
            
            resampledLeft = resample(currentLeft, 101, numLeftSamples);
            resampledRight = resample(currentRight, 101, numRightSamples);
            
            % Append to EMGCycle
            leftEmgCycle(k,:) = resampledLeft;
            rightEmgCycle(k,:) = resampledRight;
            
        end
        
        accumulatedEMG.left.(muscles{j}) = [accumulatedEMG.left.(muscles{j}); leftEmgCycle];
        accumulatedEMG.right.(muscles{j}) = [accumulatedEMG.right.(muscles{j}); rightEmgCycle];
                
    end
    
end

% Initialize the structs to store the averaged EMG cycles
for i=1:length(muscles)
    averagedEMG.left.(muscles{i}) = [];
    averagedEMG.right.(muscles{i}) = [];
end

% Average the accumulated EMG cycles for left muscles
leftMuscles = fieldnames(accumulatedEMG.left);
for i = 1:numel(leftMuscles)
    % divide by MVC
    accumulatedEMG.left.(leftMuscles{i}) = accumulatedEMG.left.(leftMuscles{i})/max(max(accumulatedEMG.left.(leftMuscles{i})));
    %Average
    averagedEMG.left.(leftMuscles{i}) = mean(accumulatedEMG.left.(leftMuscles{i}), 1);
end

% Average the accumulated EMG cycles for right muscles
rightMuscles = fieldnames(accumulatedEMG.right);
for i = 1:numel(rightMuscles)
    % divide by MVC
    accumulatedEMG.right.(rightMuscles{i}) = accumulatedEMG.right.(rightMuscles{i})/max(max(accumulatedEMG.right.(rightMuscles{i})));
    averagedEMG.right.(rightMuscles{i}) = mean(accumulatedEMG.right.(rightMuscles{i}), 1);
end
