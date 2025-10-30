% Output: B_cycles_Struct.mat (cycles_struct)
global plot_status;
filename = "A_xsens_delsys_processed.mat"; % from A_PreProcess_xsens_emg.m
% Load structure: called walks_struct
load(fullfile(subject_save_path, filename)) % walks_struct 

%%

% Get the cycles:
signal = walks_struct.EMG.FILTERED.Walk_1.RTA(1,:); 
if plot_status==true
    figure()
    plot(signal)
    hold on; 
    % Add vertical lines
    index_Table = walks_struct.XSENS.Walk_1;
    % right indices:
    indices_right_Table = index_Table(index_Table.leg_side == "R", :);

    indices_right=indices_right_Table.start_emgIDX;

    for i = 1:length(indices_right)
        xline(indices_right(i), '--r'); % Dashed red line at each index
    end
end

%%%% ####### start segmenting 
% Go row by row of heels table and depending on Right or Left - segment
% that side 
walk_filename_dict = table('Size', [0, 3], 'VariableTypes', {'int32', 'int32', 'string'}, 'VariableNames', {'WalkNum', 'Frequency', 'Intervention'});

muscles_general = {'HAM', 'RF', 'VL', 'TA', 'MG'}; 

% get walk numbers that exist
existingWalkNums = ~ismissing(walks_struct.WalksDictionary.Filename_EMG) & ~ismissing(walks_struct.WalksDictionary.Filename_XSENS);
WALKNUMS = walks_struct.WalksDictionary(existingWalkNums, 1).WalkNum;


for wi = 1:numel(WALKNUMS)
    wnum = WALKNUMS(wi);
  
    walk_num = "Walk_"+num2str(wnum); 
    index_Table = walks_struct.XSENS.(walk_num);
    
    r_counter = 0;
    l_counter = 0;
    for i=1:size(index_Table, 1) % number of rows for indices of step cycles:
    
        % Check if R or L row:
        leg_side = index_Table(i,:).leg_side; 
        % get indices for that row
        indices_forLegSide_start = index_Table(i,:).start_emgIDX;
        indices_forLegSide_end   = index_Table(i,:).end_emgIDX;
    
        if leg_side == "L"
            l_counter = l_counter+1;
        elseif leg_side == "R"
            r_counter = r_counter+1;
        end
        
        % iterate through muscles - depending on the side
        for m = 1:length(muscles_general)
    
            % get counter:
            if leg_side == "L"
                counter = l_counter;
            elseif leg_side == "R"
                counter = r_counter;
            end
    
            muscle = leg_side + muscles_general{m}; 
            
            emg_all_muscle_sigRAW     = walks_struct.EMG.RAW.(walk_num).(muscle);
            emg_all_muscle_sigFILT    = walks_struct.EMG.FILTERED.(walk_num).(muscle);
    
            if indices_forLegSide_end > length(emg_all_muscle_sigRAW)
                indices_forLegSide_end = length(emg_all_muscle_sigRAW);
    
            end 
    
            % Now when the start passes the length - continue  - no more EMG
            if indices_forLegSide_start > length(emg_all_muscle_sigRAW)
                continue;
    
            end 
    
            % 1: numbering of all steps (L and R)
            % 2: steps for that side
            % 3: raw cycle
            % 4: up until demean + bandpass and/or notch
            % 5: rectified and LOW passed filter (of #4)
            % 6: normalized to max y peak (of #4)
            % 7: 0 to 100 x axis (of #4)
        
            cycles_struct.(walk_num).(muscle)(counter,1) = {i}; % all step orders (R and L)
            cycles_struct.(walk_num).(muscle)(counter,2) = {counter}; % Just that side order
            
            % #### 3: RAW CYCLES
            temp_cycleRAW = emg_all_muscle_sigRAW(indices_forLegSide_start:indices_forLegSide_end);
            cycles_struct.(walk_num).(muscle)(counter,3) = {temp_cycleRAW};
            
            % #### 4: FILTERED CYCLES (long signals segmented after filteringPipeline_function - demean, bandpass, and notched):
            
            temp_cycleFILT    = emg_all_muscle_sigFILT(indices_forLegSide_start:indices_forLegSide_end);
            cycles_struct.(walk_num).(muscle)(counter,4) = {temp_cycleFILT};
            
            % #### 5: Rectified and LOW pass filtered (5 Hz)
            temp_cycle_rectified = abs(temp_cycleFILT);

            % Low-pass filter (envelope)
            fcut = 5; % Cutoff frequency in Hz
            EMG_Fs=2000;
            [b, a] = butter(2, fcut / (EMG_Fs / 2), 'low');
            temp_cycle_envelope = filtfilt(b, a, temp_cycle_rectified);
            cycles_struct.(walk_num).(muscle)(counter,5) = {temp_cycle_envelope};
            
            % #### 6: Normalize to max y peak
            temp_cycle_normalY = temp_cycle_envelope/max(temp_cycle_envelope);
            cycles_struct.(walk_num).(muscle)(counter,6) = {temp_cycle_normalY};
            
            % #### 7: 0 to 100 x axis
            nPoints = 100;
            originalLength = length(temp_cycle_normalY);
            originalTime = linspace(1, 100, originalLength); 
    
            newTime = linspace(1, 100, nPoints);
    
            temp_cycle_normalX = interp1(originalTime, temp_cycle_normalY, newTime, 'linear');
            cycles_struct.(walk_num).(muscle)(counter,7) = {temp_cycle_normalX};
            
    
            clear temp_cycleRAW 
            clear temp_cycleFILT 
            
            
        
            
        end
        
    
    
    end
    
    % Get corresponding frequency and intervention name to connect
    % to a walk:

    corres_walk = walks_struct.WalksDictionary(walks_struct.WalksDictionary.WalkNum== wnum, :).Filename_EMG; 
    parts = split(corres_walk, '_');

    % Extract the first part and extract the number
    first_part = parts{1}; % Get the first part as a character vector
    frequency = str2double(regexp(first_part, '\d+', 'match', 'once')); % Extract the number

    if isnan(frequency)
        frequency = 0;
        
    end % get rmt or tol
    intervention = regexp(first_part, '[a-zA-Z]+', 'match'); 
    intervention = strjoin(intervention, ''); 
    if intervention == "NO"
        intervention = "NO_STIM";
    end
   

    walk_filename_dict = [walk_filename_dict; {wnum, frequency, intervention}]; 
end


cycles_struct.WalksDict = walk_filename_dict; 


% SAVE GAIT CYCLE STRUCT

save(fullfile(subject_save_path,'B_cycles_Struct.mat'), 'cycles_struct');


