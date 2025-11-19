function [accumulatedJointAngles, averagedXSENS]  = downSampleAveragedXSENS(allXSENS, processedGait, joints, filterJointsConfig, sf)

num_points = 101;

fc = filterJointsConfig.LOWPASS_CUTOFF;
n = filterJointsConfig.LOWPASS_ORDER;

[b, a] = butter(n,fc/(sf/2),'low');

xsensTrials = fieldnames(allXSENS);
gaitTrials = fieldnames(processedGait);

% Initialize the structs to store the accumulated joint angles
for i=1:length(joints)
    accumulatedJointAngles.right.(joints{i}) = [];
    accumulatedJointAngles.left.(joints{i}) = [];
end

for i = 1:numel(gaitTrials)
    
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
    
    if length(gait.leftStanceEMG) > length(gait.rightStanceEMG)        
        cycle = length(gait.rightStanceEMG(:,1));        
    else        
        cycle = length(gait.leftStanceEMG(:,1));        
    end
    
    for j = 1:length(rightJoints)
        resampledDataRight{j} = [];
        resampledDataLeft{j} = [];
        for k = 1:cycle
            % Get jointAngles of Stance - Swing Phase
            currentLeft = jointAngles.left.(leftJoints{j})(gait.leftStanceXSENS(k,1):gait.leftSwingXSENS(k,2));
            currentRight = jointAngles.right.(rightJoints{j})(gait.rightStanceXSENS(k,1):gait.rightSwingXSENS(k,2));
            
            numLeftSamples = length(currentLeft);
            numRightSamples = length(currentRight);
            
            % Resample to a common length for averaging
            resampledLeft = resample(currentLeft, num_points, numLeftSamples);
            resampledRight = resample(currentRight, num_points, numRightSamples);
            
            % Accumulate the resampled data for each joint across all trials
            accumulatedJointAngles.right.(rightJoints{j}) = [accumulatedJointAngles.right.(rightJoints{j}); resampledRight'];
            accumulatedJointAngles.left.(leftJoints{j}) = [accumulatedJointAngles.left.(leftJoints{j}); resampledLeft'];
        end
    end
end

% Calculate the average for each joint across all trials
rightJoints = fieldnames(accumulatedJointAngles.right);
leftJoints = fieldnames(accumulatedJointAngles.left);

for j = 1:length(rightJoints)
    averagedXSENS.right.(rightJoints{j}) = mean(accumulatedJointAngles.right.(rightJoints{j}), 1);
    averagedXSENS.left.(leftJoints{j}) = mean(accumulatedJointAngles.left.(leftJoints{j}), 1);
end
