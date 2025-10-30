function gaitCycleResultTable = gaitrite_processing_GaitCycles(inputStruct, GAIT_Fs, EMG_Fs, X_Fs)
    gaitCycleResultTable = table(); 

    fieldNames = fieldnames(inputStruct);

    for k = 1:length(fieldNames) % Here going through each PRE/POST SSV and FV

        GR_filename = fieldNames{k}; % TO BE SAVED
        data = inputStruct.(GR_filename);

        unique_trials = unique(data(:,2)); % Find the unique trial numbers
        trials_struct = struct(); % Initialize a structure to hold the trials

        % Loop through each unique trial number and separate the data
        for i = 1:length(unique_trials)
            trial_number = unique_trials(i);
            trial_name = sprintf('trial%d', i);

            trials_struct.(trial_name) = data(data(:,2) == trial_number, :);
        end


        trials = fieldnames(trials_struct);

        for t = 1:length(trials) % ITERATING THROUGH EACH TRIALS

            trial_renumbered = t; % TO BE SAVED (RENUMBERED TO 1,2,3)
            trial_number = unique_trials(t); % TO BE SAVED (GR OG)

            data = trials_struct.(trials{t});

            left_right = data(:, 6); % 0 is left, 1 is right

            % seconds the event occurs
            heel_on = data(:, 36);
            heel_off = data(:, 37);
            toe_on = data(:, 40);
            toe_off = data(:, 41);
            step_Len = data(:,16);
            stride_Len = data(:,17);
            swing_time = data(:,21);
            stride_vel = data(:,25);
            stance_time = data(:,22); % reason why stance is not added?

            leftStance = [];
            rightStance = [];
            leftSwing = [];
            rightSwing = [];

            gaitCycleNUM = 1; 
            for i = 1:length(left_right)-2
                heel_on_1_s  = heel_on(i);  % TO BE SAVED
                toe_on_1_s   = toe_on(i);   % TO BE SAVED - might not need
                heel_off_1_s = heel_off(i); % TO BE SAVED
                toe_off_1_s  = toe_off(i);  % TO BE SAVED
                heel_on_2_s  = heel_on(i+2);% TO BE SAVED - this is the heel on of next step

                % Convert to index GR
                heel_on_1_idxGR  = heel_on_1_s *GAIT_Fs;    % TO BE SAVED 
                toe_on_1_idxGR   = toe_on_1_s  *GAIT_Fs;   % TO BE SAVED 
                heel_off_1_idxGR = heel_off_1_s*GAIT_Fs;   % TO BE SAVED
                toe_off_1_idxGR  = toe_off_1_s *GAIT_Fs;   % TO BE SAVED
                heel_on_2_idxGR  = heel_on_2_s *GAIT_Fs;   % TO BE SAVED 

                % Convert to XSENS index
                heel_on_1_idxXS  = heel_on_1_s *X_Fs;    % TO BE SAVED 
                toe_on_1_idxXS   = toe_on_1_s  *X_Fs;   % TO BE SAVED 
                heel_off_1_idxXS = heel_off_1_s*X_Fs;   % TO BE SAVED
                toe_off_1_idxXS  = toe_off_1_s *X_Fs;   % TO BE SAVED
                heel_on_2_idxXS  = heel_on_2_s *X_Fs;   % TO BE SAVED 

                % Convert to EMG index
                heel_on_1_idxEMG  = heel_on_1_s *EMG_Fs;    % TO BE SAVED 
                toe_on_1_idxEMG   = toe_on_1_s  *EMG_Fs;   % TO BE SAVED 
                heel_off_1_idxEMG = heel_off_1_s*EMG_Fs;   % TO BE SAVED
                toe_off_1_idxEMG  = toe_off_1_s *EMG_Fs;   % TO BE SAVED
                heel_on_2_idxEMG  = heel_on_2_s *EMG_Fs;   % TO BE SAVED 

                % Getting step lenghts 
                stepL_oppositeLeg_cm = step_Len(i+1); % TO BE SAVED - this is the sLength of other leg in gait cyle - this precedes
                stepL_thisLeg_cm = step_Len(i+2);     % TO BE SAVED

                strideLength_cm = stride_Len(i+2); 
                strideVelocity_mps = stride_vel(i+2)/100; 

                % Temporal 
                stanceTime = stance_time(i);
                swingTime = swing_time(i+2); % TO BE SAVED - this is recorded in the next step ( heel_on_2-toe_off_1)
                % Self calculated with toe off/heel on numbers
                stanceTime_selfCalc = toe_off_1_s-heel_on_1_s;
                swingTime_selfCalc = heel_on_2_s-toe_off_1_s;

                % Total length gait cycle
                total_gait_cycle_s = stanceTime + swingTime;      % TO BE SAVED
                stanceProportion = stanceTime/total_gait_cycle_s; % TO BE SAVED
                swingProportion = swingTime/total_gait_cycle_s;   % TO BE SAVED

                if left_right(i) == 0
                    leg_side = "L"; % TO BE SAVED
                else 
                    leg_side = "R"; % TO BE SAVED
                end

                % MIGHT NEED TO SAVE HERE - SINCE IT IS WHERE IT GOES BY STEP 

                tempTable = table( string(GR_filename),trial_renumbered, gaitCycleNUM, trial_number, leg_side, ...
                    stanceTime, swingTime, total_gait_cycle_s, stanceProportion, swingProportion, ...
                    stepL_oppositeLeg_cm, stepL_thisLeg_cm, strideLength_cm, strideVelocity_mps, ...
                    heel_on_1_s, toe_on_1_s, heel_off_1_s, toe_off_1_s, heel_on_2_s,   ...
                    heel_on_1_idxGR, toe_on_1_idxGR, heel_off_1_idxGR, toe_off_1_idxGR, heel_on_2_idxGR, ...
                    heel_on_1_idxXS, toe_on_1_idxXS, heel_off_1_idxXS, toe_off_1_idxXS, heel_on_2_idxXS, ...
                    heel_on_1_idxEMG, toe_on_1_idxEMG, heel_off_1_idxEMG, toe_off_1_idxEMG, heel_on_2_idxEMG);


                % Append the temporary table to the result table
                gaitCycleResultTable = [gaitCycleResultTable; tempTable];


                gaitCycleNUM = 1+gaitCycleNUM; 

            end

        end

    end
end