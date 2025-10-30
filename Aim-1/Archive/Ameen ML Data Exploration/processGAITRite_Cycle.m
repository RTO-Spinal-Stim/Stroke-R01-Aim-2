function processedGait = processGAITRite_Cycle(inputStruct,GAIT_Fs, EMG_Fs, X_Fs)
   
%     inputStruct = gaitStruct;
    processedGait = struct();

    fieldNames = fieldnames(inputStruct);

    for k = 1:length(fieldNames)
        data = inputStruct.(fieldNames{k});
        
        unique_trials = unique(data(:,2)); % Find the unique trial numbers
        trials_struct = struct(); % Initialize a structure to hold the trials

        % Loop through each unique trial number and separate the data
        for i = 1:length(unique_trials)
            trial_number = unique_trials(i);
            trial_name = sprintf('trial%d', i);
            trials_struct.(trial_name) = data(data(:,2) == trial_number, :);
        end

        
        trials = fieldnames(trials_struct);
        
        for t = 1:length(trials)
        
        data = trials_struct.(trials{t});
        
        left_right = data(:, 6); 
        heel_on = data(:, 36);
        heel_off = data(:, 37);
        toe_on = data(:, 40);
        toe_off = data(:, 41);
        step_Len = data(:,16);
        swing_time = data(:,21);
        stride_Velocity = data(:, 25);

        leftStance = [];
        rightStance = [];
        leftSwing = [];
        rightSwing = [];

        for i = 1:length(left_right)-2
            if left_right(i) == 0
                leftStance(end+1,:) = [heel_on(i), toe_off(i)];
                leftSwing(end+1,:) = [toe_off(i), heel_on(i+2)];
            else 
                rightStance(end+1,:) = [heel_on(i), toe_off(i)];
                rightSwing(end+1,:) = [toe_off(i), heel_on(i+2)];
            end
        end
        
        for i = 2:length(left_right)-1
            
            stepLenSym(i-1) = (2*abs(step_Len(i)-step_Len(i+1)))/(step_Len(i)+step_Len(i+1));
             
        end
        
        for i = 3:length(left_right)-1
            
            swingTimeSym(i-2) = (2*abs(swing_time(i)-swing_time(i+1)))/(swing_time(i)+swing_time(i+1));
            
        end
        
        for i = 3:length(left_right)-1
            
            strideVelocitySym(i-2) = (2*abs(stride_Velocity(i)-stride_Velocity(i+1)))/(stride_Velocity(i)+stride_Velocity(i+1));
            
        end

        leftZeroRows = all(leftStance == 0, 2);
        rightZeroRows = all(rightStance == 0,2);

        leftStance(leftZeroRows, :) = [];
        rightStance(rightZeroRows, :) = [];
        leftSwing(leftZeroRows, :) = [];
        rightSwing(rightZeroRows, :) = [];

         leftStance = round(leftStance * GAIT_Fs);
        rightStance = round(rightStance * GAIT_Fs);
        leftSwing = round(leftSwing * GAIT_Fs);
        rightSwing = round(rightSwing * GAIT_Fs);

        leftStanceTime = leftStance(:,2)-leftStance(:,1);
        rightStanceTime = rightStance(:,2)-rightStance(:,1);
        leftSwingTime = leftSwing(:,2)-leftSwing(:,1);
        rightSwingTime = rightSwing(:,2)-rightSwing(:,1);

        leftStanceTime = round(mean(leftStanceTime));
        rightStanceTime = round(mean(rightStanceTime));
        leftSwingTime = round(mean(leftSwingTime));
        rightSwingTime = round(mean(rightSwingTime));

        totalLeft = leftStanceTime + leftSwingTime;
        totalRight = rightStanceTime + rightSwingTime;

        leftStanceProportion = leftStanceTime/totalLeft;
        leftSwingProportion = leftSwingTime/totalLeft;
        rightStanceProportion = rightStanceTime/totalRight;
        rightSwingProportion = rightSwingTime/totalRight;

        leftNormal = 0:100;
        rightNormal = 0:100;

        leftSwingIdx = round(leftStanceProportion * 101)+1;
        rightSwingIdx = round(rightStanceProportion * 101)+1;
        
        % Convert time indices to 1926 Hz frequency for EMG
        leftStanceEMG = round(leftStance * EMG_Fs / GAIT_Fs);
        rightStanceEMG = round(rightStance * EMG_Fs / GAIT_Fs);
        leftSwingEMG = round(leftSwing * EMG_Fs / GAIT_Fs);
        rightSwingEMG = round(rightSwing * EMG_Fs / GAIT_Fs);
        
        % Convert time indices to 100 Hz frequency for XSENS
        leftStanceXSENS = round(leftStance * X_Fs / GAIT_Fs);
        rightStanceXSENS = round(rightStance * X_Fs / GAIT_Fs);
        leftSwingXSENS = round(leftSwing * X_Fs / GAIT_Fs);
        rightSwingXSENS = round(rightSwing * X_Fs / GAIT_Fs);
        
%         %Average Step Len Sym
%         StepLenSym = mean(stepLenSym);
%         
%         %Average Swing Time Sym
%         SwingTimeSym = mean(swingTimeSym);

        processedGait.(fieldNames{k}).(trials{t}) = struct(...
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
            'StepLenSym', stepLenSym, ...
            'SwingTimeSym', swingTimeSym, ...
            'StrideVelocitySym', strideVelocitySym);
        
        end
    end
end
