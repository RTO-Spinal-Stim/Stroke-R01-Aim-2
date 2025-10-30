function processedGait = processGAITRite_Old(inputStruct,GAIT_Fs, EMG_Fs, X_Fs)

%% PURPOSE: PROCESS THE GAIT RITE:
% 1. Isolate the individual trials (by unique Gait_Id)
% 2. 

processedGait = struct();

xlsFileNames = fieldnames(inputStruct);

num_points = 101;
startPoint = 0;
endPoint = 100;
leftNormal = linspace(startPoint, endPoint, num_points);
rightNormal = linspace(startPoint, endPoint, num_points);

for k = 1:length(xlsFileNames)
    data = inputStruct.(xlsFileNames{k});

    unique_trials = unique(data(:,2)); % Find the unique trial numbers
    trials_struct = struct(); % Initialize a structure to hold the trials

    % 1. Loop through each unique trial number and separate the data
    for i = 1:length(unique_trials)
        trial_number = unique_trials(i);
        trial_name = sprintf('trial%d', i);
        trials_struct.(trial_name) = data(data(:,2) == trial_number, :);
    end

    trials = fieldnames(trials_struct);
    for t = 1:length(trials)

        data = trials_struct.(trials{t});

        left_right = data(:, 6); % 0 = L, 1 = R
        heel_on = data(:, 36);
        heel_off = data(:, 37);
        toe_on = data(:, 40);
        toe_off = data(:, 41);
        step_Len = data(:,16);
        swing_time = data(:,21);

        leftStanceSeconds = zeros(length(left_right)-2,2);
        rightStanceSeconds = zeros(length(left_right)-2,2);
        leftSwingSeconds = zeros(length(left_right)-2,2);
        rightSwingSeconds = zeros(length(left_right)-2,2);
        
        stepLenSym = NaN(length(left_right)-2,1);
        swingTimeSym = NaN(length(left_right)-3,1);

        for i = 1:length(left_right)-2
            if left_right(i) == 0
                leftStanceSeconds(i,:) = [heel_on(i), toe_off(i)];
                leftSwingSeconds(i,:) = [toe_off(i), heel_on(i+2)];
            else
                rightStanceSeconds(i,:) = [heel_on(i), toe_off(i)];
                rightSwingSeconds(i,:) = [toe_off(i), heel_on(i+2)];
            end
        end
        
        % Step length symmetry
        for i = 2:length(left_right)-1
            stepLenSym(i-1) = (2*abs(step_Len(i)-step_Len(i+1)))/(step_Len(i)+step_Len(i+1));
        end

        % Swing time symmetry
        for i = 3:length(left_right)-1
            swingTimeSym(i-2) = (2*abs(swing_time(i)-swing_time(i+1)))/(swing_time(i)+swing_time(i+1));
        end

        leftZeroRows = all(leftStanceSeconds == 0, 2);
        rightZeroRows = all(rightStanceSeconds == 0,2);

        % Remove the NaN rows.
        leftStanceSeconds(leftZeroRows, :) = [];
        rightStanceSeconds(rightZeroRows, :) = [];
        leftSwingSeconds(leftZeroRows, :) = [];
        rightSwingSeconds(rightZeroRows, :) = [];

        % Convert durations from seconds to GaitRite indices
        leftStanceIndices = round(leftStanceSeconds * GAIT_Fs);
        rightStanceIndices = round(rightStanceSeconds * GAIT_Fs);
        leftSwingIndices = round(leftSwingSeconds * GAIT_Fs);
        rightSwingIndices = round(rightSwingSeconds * GAIT_Fs);

        leftStanceDurations = leftStanceIndices(:,2)-leftStanceIndices(:,1);
        rightStanceDurations = rightStanceIndices(:,2)-rightStanceIndices(:,1);
        leftSwingTimeDurations = leftSwingIndices(:,2)-leftSwingIndices(:,1);
        rightSwingTimeDurations = rightSwingIndices(:,2)-rightSwingIndices(:,1);

        leftStanceDuration = round(mean(leftStanceDurations));
        rightStanceDuration = round(mean(rightStanceDurations));
        leftSwingTimeDuration = round(mean(leftSwingTimeDurations));
        rightSwingTimeDuration = round(mean(rightSwingTimeDurations));

        totalLeft = leftStanceDuration + leftSwingTimeDuration;
        totalRight = rightStanceDuration + rightSwingTimeDuration;

        leftStanceProportion = leftStanceDuration/totalLeft;
        leftSwingProportion = leftSwingTimeDuration/totalLeft;
        rightStanceProportion = rightStanceDuration/totalRight;
        rightSwingProportion = rightSwingTimeDuration/totalRight;        

        leftSwingIdx = round(leftStanceProportion * num_points)+1;
        rightSwingIdx = round(rightStanceProportion * num_points)+1;

        % Convert time indices to 2000 Hz frequency for EMG
        leftStanceEMG = round(leftStanceIndices * EMG_Fs / GAIT_Fs);
        rightStanceEMG = round(rightStanceIndices * EMG_Fs / GAIT_Fs);
        leftSwingEMG = round(leftSwingIndices * EMG_Fs / GAIT_Fs);
        rightSwingEMG = round(rightSwingIndices * EMG_Fs / GAIT_Fs);

        % Convert time indices to 100 Hz frequency for XSENS
        leftStanceXSENS = round(leftStanceIndices * X_Fs / GAIT_Fs);
        rightStanceXSENS = round(rightStanceIndices * X_Fs / GAIT_Fs);
        leftSwingXSENS = round(leftSwingIndices * X_Fs / GAIT_Fs);
        rightSwingXSENS = round(rightSwingIndices * X_Fs / GAIT_Fs);

        %Average Step Len Sym
        avgStepLenSym = mean(stepLenSym);

        %Average Swing Time Sym
        avgSwingTimeSym = mean(swingTimeSym);

        processedGait.(xlsFileNames{k}).(trials{t}) = struct(...
            'leftSwingIdx', leftSwingIdx, ...
            'rightSwingIdx', rightSwingIdx, ...
            'leftNormal', leftNormal, ...
            'rightNormal', rightNormal, ...
            'leftStanceEMG', leftStanceEMG, ...
            'rightStanceEMG', rightStanceEMG, ...
            'leftSwingEMG', leftSwingEMG, ...
            'rightSwingEMG', rightSwingEMG, ...
            'leftStanceXSENS', leftStanceXSENS, ...
            'rightStanceXSENS', rightStanceXSENS, ...
            'leftSwingXSENS', leftSwingXSENS, ...
            'rightSwingXSENS', rightSwingXSENS, ...
            'avgStepLenSym', avgStepLenSym, ...
            'avgSwingTimeSym', avgSwingTimeSym);

    end
end
end
