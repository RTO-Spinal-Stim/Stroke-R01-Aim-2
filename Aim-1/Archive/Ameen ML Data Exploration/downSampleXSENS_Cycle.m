function accumulatedJointAngles = downSampleXSENS_Cycle(allXSENS, processedGait)

    xsensTrials = fieldnames(allXSENS);
    gaitTrials = fieldnames(processedGait);


    for i = 1:numel(gaitTrials)
        
        % Initialize the structs to store the accumulated joint angles
        accumulatedJointAngles.(xsensTrials{i}).right = struct('H', [], 'K', [], 'A', []);
        accumulatedJointAngles.(xsensTrials{i}).left = struct('H', [], 'K', [], 'A', []);

        trialXsens = xsensTrials{i};
        trialGait = gaitTrials{i};

        Xsens = allXSENS.(trialXsens);
        gait = processedGait.(trialGait);
   

        % Joint angles
        RH = Xsens(2:end,46);
        RK = Xsens(2:end,49);
        RA = Xsens(2:end,52);
        LH = Xsens(2:end,58);
        LK = Xsens(2:end,61);
        LA = Xsens(2:end,64);
        
        
    % Find the index of the first NaN value
    first_nan_index = find(isnan(RH), 1, 'first');

    % If there is a NaN value, trim the signal
    if ~isempty(first_nan_index)
        
        % Joint angles trimmed
        RH = Xsens(2:first_nan_index-1,46);
        RK = Xsens(2:first_nan_index-1,49);
        RA = Xsens(2:first_nan_index-1,52);
        LH = Xsens(2:first_nan_index-1,58);
        LK = Xsens(2:first_nan_index-1,61);
        LA = Xsens(2:first_nan_index-1,64);
        
        
    end

        
        
        
        
        % Filter
        sf = 100; % sampling frequency
        fc = 6; % cutoff frequency
        n = 4; % filter order
        [b, a] = butter(n,fc/(sf/2),'low');
             
        filtRH = zeros(size(RH));
        filtRK = zeros(size(RK));
        filtRA = zeros(size(RA));
        filtLH = zeros(size(LH));
        filtLK = zeros(size(LK));
        filtLA = zeros(size(LA));

        % Use indexing to fill the preallocated arrays
        filtRH(:) = filtfilt(b, a, RH);
        filtRK(:) = filtfilt(b, a, RK);
        filtRA(:) = filtfilt(b, a, RA);
        filtLH(:) = filtfilt(b, a, LH);
        filtLK(:) = filtfilt(b, a, LK);
        filtLA(:) = filtfilt(b, a, LA);
        
        % Create a struct with 'right' and 'left' fields
        jointAngles.right = struct('H', filtRH, 'K', filtRK, 'A', filtRA);
        jointAngles.left = struct('H', filtLH, 'K', filtLK, 'A', filtLA);

        rightJoints = fieldnames(jointAngles.right);
        leftJoints = fieldnames(jointAngles.left);

        % Initialize cell arrays to store resampled data for averaging
        resampledDataRight = cell(1, length(rightJoints));
        resampledDataLeft = cell(1, length(leftJoints));
        
            % if length(gait.leftStanceEMG) > length(gait.rightStanceEMG)
            % 
            %     cycle = length(gait.rightStanceEMG(:,1));
            % 
            % else
            % 
            %     cycle = length(gait.leftStanceEMG(:,1));
            % 
            % end

        for j = 1:length(rightJoints)
            resampledDataRight{j} = [];
            resampledDataLeft{j} = [];
            for r = 1:length(gait.rightStanceXSENS(:,1))
                % Get jointAngles of Stance - Swing Phase
                currentRight = jointAngles.right.(rightJoints{j})(gait.rightStanceXSENS(r,1):gait.rightSwingXSENS(r,2));

                numRightSamples = length(currentRight);

                % Resample to a common length for averaging
                resampledRight = resample(currentRight, 101, numRightSamples);

                % Accumulate the resampled data for each joint across all trials
                accumulatedJointAngles.(xsensTrials{i}).right.(rightJoints{j}) = [accumulatedJointAngles.(xsensTrials{i}).right.(rightJoints{j}); resampledRight'];
            end
            
            for l = 1:length(gait.leftStanceXSENS(:,1))
                % Get jointAngles of Stance - Swing Phase
                currentLeft = jointAngles.left.(leftJoints{j})(gait.leftStanceXSENS(l,1):gait.leftSwingXSENS(l,2));

                numLeftSamples = length(currentLeft);

                % Resample to a common length for averaging
                resampledLeft = resample(currentLeft, 101, numLeftSamples);

                % Accumulate the resampled data for each joint across all trials
                accumulatedJointAngles.(xsensTrials{i}).left.(leftJoints{j}) = [accumulatedJointAngles.(xsensTrials{i}).left.(leftJoints{j}); resampledLeft'];
            end
        end
        
        %Determine leading foot
        if gait.leftStanceXSENS(1,1) < gait.rightStanceXSENS(1,1)    
            accumulatedJointAngles.(xsensTrials{i}).leadingFoot = 'left';   
        else
            accumulatedJointAngles.(xsensTrials{i}).leadingFoot = 'right';  
        end
        
    end
    
end

