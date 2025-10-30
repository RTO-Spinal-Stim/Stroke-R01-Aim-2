function [accumulatedEMG] = downSampleEMG_Cycle(filteredEMG, processedGait)

    emgTrials = fieldnames(filteredEMG);
    gaitTrials = fieldnames(processedGait);
    
    muscles = {'HAM', 'RF', 'MG', 'TA', 'VL'};

    
    % Initialize arrays to hold trial and cycle numbers
%     accumulatedEMG.trialNumbers = [];
%     accumulatedEMG.cycleNumbers = [];

    for i = 1:numel(gaitTrials)
        
        % Initialize the accumulated EMG cycles
        accumulatedEMG.(emgTrials{i}).left = struct('HAM', [], 'RF', [], 'MG', [], 'TA', [], 'VL', []);
        accumulatedEMG.(emgTrials{i}).right = struct('HAM', [], 'RF', [], 'MG', [], 'TA', [], 'VL', []);

        trialEMG = emgTrials{i};
        trialGait = gaitTrials{i};

        EMGall = filteredEMG.(trialEMG);
        muscle = fieldnames(EMGall);

        % Separate left/right muscles
        for h = 1:numel(muscles)
            EMG.left.(muscles{h}) = EMGall.(muscle{h+5});
            EMG.right.(muscles{h}) = EMGall.(muscle{h});
        end
        
        gait = processedGait.(trialGait);

%         if length(gait.leftStanceEMG) > length(gait.rightStanceEMG)
%             cycle = length(gait.rightStanceEMG);
%         else
%             cycle = length(gait.leftStanceEMG);
%         end

        for r = 1:length(gait.rightStanceEMG(:,1))
            % Record trial and cycle number once per gait cycle
            %accumulatedEMG.trialNumbers = [accumulatedEMG.trialNumbers; i];
            %accumulatedEMG.cycleNumbers = [accumulatedEMG.cycleNumbers; k];

            for j = 1:numel(muscles)
                EMGright = EMG.right.(muscles{j});

                % Get EMG of Stance - Swing Phase
                currentRight = EMGright(gait.rightStanceEMG(r, 1):gait.rightSwingEMG(r, 2));

                numRightSamples = length(currentRight);
                
                resampledRight = resample(currentRight, 101, numRightSamples);

                % Normalize within the current trial cycle
                maxRight = max(resampledRight);
                if maxRight > 0
                    resampledRight = resampledRight / maxRight;
                end

                % Append the resampled and normalized data for each cycle
                accumulatedEMG.(emgTrials{i}).right.(muscles{j}) = [accumulatedEMG.(emgTrials{i}).right.(muscles{j}); resampledRight];
            end
        end
        
        for l = 1:length(gait.leftStanceEMG(:,1))
            % Record trial and cycle number once per gait cycle
            %accumulatedEMG.trialNumbers = [accumulatedEMG.trialNumbers; i];
            %accumulatedEMG.cycleNumbers = [accumulatedEMG.cycleNumbers; k];

            for j = 1:numel(muscles)
                EMGleft = EMG.left.(muscles{j});

                % Get EMG of Stance - Swing Phase
                currentLeft = EMGleft(gait.leftStanceEMG(l, 1):gait.leftSwingEMG(l, 2));

                numLeftSamples = length(currentLeft);

                resampledLeft = resample(currentLeft, 101, numLeftSamples);

                % Normalize within the current trial cycle
                maxLeft = max(resampledLeft);
                if maxLeft > 0
                    resampledLeft = resampledLeft / maxLeft;
                end

                % Append the resampled and normalized data for each cycle
                accumulatedEMG.(emgTrials{i}).left.(muscles{j}) = [accumulatedEMG.(emgTrials{i}).left.(muscles{j}); resampledLeft];
            end
        end
        
        %Determine leading foot
        if gait.leftStanceEMG(1,1) < gait.rightStanceEMG(1,1)    
            accumulatedEMG.(emgTrials{i}).leadingFoot = 'left';   
        else
            accumulatedEMG.(emgTrials{i}).leadingFoot = 'right';  
        end
        
    end
end
