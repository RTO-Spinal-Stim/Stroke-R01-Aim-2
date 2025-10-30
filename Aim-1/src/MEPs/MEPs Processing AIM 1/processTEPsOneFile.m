function [processedRow, logInfo] = processTEPsOneFile(config, rowIn, trialFilePath, correctedChannelsStruct)

%% PURPOSE: PROCESS ONE INDIVIDUAL TRIAL OF TEPs 
% PART A OF NICOLE'S PIPELINE.
% Inputs:
% config: The configuration struct loaded from JSON
% rowIn: A table with one row of data from the TEPs log.
% trialFilePath: Char path to the file for this trial.
% correctedChannelsStruct: Loaded from JSON, identifies which channels need
% to be corrected.

processedRow = table;

%% Config
TEPcolNamesConfig = config.TEPS_LOG_COLUMN_NAMES;
prePostColNameHeader = TEPcolNamesConfig.PRE_POST_COLUMN;
tepFileNameHeader = TEPcolNamesConfig.TEP_FILENAME;
subjectNameHeader = TEPcolNamesConfig.SUBJECT_NAME;
pareticSideHeader = TEPcolNamesConfig.PARETIC_SIDE;
sessionCodeHeader = TEPcolNamesConfig.SESSION_CODE;
pulsesToDeleteHeader = TEPcolNamesConfig.PULSES_TO_DELETE;
timepointHeader = TEPcolNamesConfig.TIMEPOINT;
final_muscles_list = convertCharsToStrings(config.MUSCLES);
number_of_muscles = length(final_muscles_list);
pulses_perIntensity = config.NUM_PULSES_PER_INTENSITY;
sampleRate = config.SAMPLE_RATE;
windowDuration = config.WINDOW_DURATION; % Window duration (seconds)

mapped_interventions = containers.Map(config.INTERVENTION_FOLDERS, config.MAPPED_INTERVENTION_FIELDS);

processedRow.Name{1} = ['SS' rowIn.(subjectNameHeader){1} '_' mapped_interventions(rowIn.(sessionCodeHeader){1}) '_' rowIn.(prePostColNameHeader){1}];

%% Filter
% Don't do highpass filter, it adds low-freq distortion [Inanici, 2018]
% Lowpass filter config
lowpassFilterConfig = config.LOWPASS_FILTER;
low = lowpassFilterConfig.LOWPASS_CUTOFF; % [Inanici, 2018]
lowpassOrder = lowpassFilterConfig.ORDER;
[f,e] = butter(lowpassOrder,low/(sampleRate/2),'low');

% Bandpass filter config
bandpassFilterConfig = config.BANDPASS_FILTER;
%A. Bandpass filter design (20-500 Hz)
low_cutoff = bandpassFilterConfig.LOW_CUTOFF;  % Lower cutoff frequency (Hz)
high_cutoff = bandpassFilterConfig.HIGH_CUTOFF; % Upper cutoff frequency (Hz)
bandpassOrder = bandpassFilterConfig.ORDER;
[b, a] = butter(bandpassOrder, [low_cutoff, high_cutoff]/(sampleRate/2), 'bandpass');

% Get subject - print all details
subject = rowIn.(subjectNameHeader){1};
fileName = rowIn.(tepFileNameHeader){1};
paretic_side = rowIn.(pareticSideHeader){1};
timepoint = rowIn.(prePostColNameHeader){1};
session_code = rowIn.(sessionCodeHeader){1};
pulsesToDelete = rowIn.(pulsesToDeleteHeader){1};

disp([num2str(subject), ' ', timepoint, ' - ', session_code]);

%% Load the file.
% Variables in file:
% blocktimes
% com: Comments metadata
% comtext: The text of the comments
% data: All muscles' data as a 1xN vector, where N = # samples * # muscles
% dataend: M x N double indexing into data vector, where M = # muscles, N = # pulses
% datastart M x N double indexing into data vector, where M = # muscles, N = # pulses
% firstsampleoffset: Always all zeros?
% rangemax: 
% rangemin
% samplerate: M x N double of sample rates, where M = # muscles, N = # pulses. Should always be the same number.
% tickrate: 1xN vector of sample rates (?), where N = # pulses
% titles: The names of the muscles. MxN char array, where M = # channels 
% (# muscles + 1 for trigger), and N = length of longest channel name
% unittext: units, 2x2 array (1: mV, 2: V)
% unittextmap: MxN double indexing the units of each channel (using values from unittext)
load(trialFilePath, 'titles','data', 'datastart', 'dataend', 'com', 'comtext');

% Identify the bad pulses.
delete_in = getBadPulses(pulsesToDelete);

% Find rows that contain RVL, LRV, STIM, and KNEE to delete
emptyrow_title_in = [ find(ismember(titles,'RKne','rows')) find(ismember(titles,'LKne','rows')) find(ismember(titles,'Stim','rows'))];

% Final set of titles
titles(emptyrow_title_in,:) = [];
% Final rows of data
datastart(emptyrow_title_in,:) = [];

% Get the order of channels presented in the mat file
channels = cell(number_of_muscles,1);
for channel_num = 1:size(titles,1)
    currTitle = strtrim(titles(channel_num,:));
    if ismember(currTitle, final_muscles_list)
        channels{channel_num} = currTitle; % gives order of channels in the data
    end
end

%% Correcting the channels namings that were mislabeled
if isfield(session_code, fieldnames(correctedChannelsStruct))
    channels = correctedChannelsStruct.(intervention);
end

%% Creating the structs of raw data
EMG_raw_struct = struct_raw_EMG_trials(channels, data, datastart, dataend, delete_in);
processedRow.Raw_EMG = EMG_raw_struct;

%% Check the pulses
total_pulses=size(EMG_raw_struct.(final_muscles_list{1}),1); % Arbitrary muscle
logInfo = '';
if mod(total_pulses, pulses_perIntensity) ~= 0
    disp([subject, '_', session_code, '_',timepoint]);
    disp(['... (ERR) != ' num2str(pulses_perIntensity)  ' pulses per intensities detected. Please check pulses #s to remove']);
    % ADD TO ERROR LIST:
    disp(['Pulses to remove: ' delete_in]);
    logInfo = [subject, '_', session_code, '_', timepoint, ' Total Pulses: ' num2str(total_pulses)];
end
processedRow.LogInfo = {logInfo};

%% Try to pattern match a MEP with a sine wave
resultsTable = table;
channels = fieldnames(processedRow.Raw_EMG);
largestSpikeRegression = struct;
for channelNum = 1:length(channels)
    for pulseNum=1:total_pulses        
        tic;
        channel = channels{channelNum};
        channel = 'RRF';
        channelData = processedRow.Raw_EMG.(channel)(pulseNum,:);
        [resultTable] = patternMatchMEP(channelData, pulseNum);
        if height(resultTable) > 0
            resultTable.PulseNum = ones(height(resultTable), 1) * pulseNum;
            resultTable.Channel = repmat({channel},height(resultTable),1);
        end
        toc;
        resultsTable = [resultsTable; resultTable];
        disp([channel ' Pulse ' num2str(pulseNum)])
    end
    
    % Filter for positive R^2 only
    resultsTable(resultsTable.R2 < 0,:) = [];
    % Normalize the P2P and lags to 1
    resultsTable.P2PNorm = resultsTable.P2P / max(resultsTable.P2P);
    resultsTable.lagNorm = resultsTable.lag / 200;
    
    
    %% Identify the line of best fit for the "mean" lag for this muscle.
    % Create an initial guess based on the longest spike. 
    % Compute the std. of the lags in this group, called `firstLagSpread`.
    % Then iteratively expand the P2P range. Expand the set of data points
    % used in the regression to include those with lags within `firstLagSpread`
    % of the line, and P2P in the bounds.
    % Then recompute the line of best fit using these points.
    
    % Get the index of the max R^2 in the highest P2P's
    topPercStartValue = 0.8; % The first cutoff
    maxP2P = max(resultsTable.P2P); % The largest observed P2P
    topPercP2PValue = topPercStartValue * maxP2P;
    minP2P = 0.05;
    nSteps = 10; % Number of times to adjust the linear regression
    P2Psteps = linspace(topPercP2PValue, minP2P, nSteps); % Define the P2P cutoffs for each iterative adjustment
    firstTopPercIdx = resultsTable.P2P > topPercP2PValue; % The first set of indices of the rows in the top N percent
    firstLagSpread = range(resultsTable.lag(firstTopPercIdx)); % The spread of the lag values in the first round of the top N percent
    % Create an initial horizontal line for a linear regression estimate
    clear b;
    b(1,1) = mean(resultsTable.lag(firstTopPercIdx));
    b(2,1) = 0;
    for i = 2:nSteps
        currP2P = P2Psteps(i);
    
        % Now at this new P2P value, which points are above this P2P level, but
        % within `firstLagSpread` distance of the line?
        topPercP2Pidx = resultsTable.P2P > currP2P; % Indices of values in the top N% P2P
        topPercP2Prows = resultsTable(topPercP2Pidx,:); % The rows in the top N% P2P
        eligibleP2Pvalues = topPercP2Prows.P2P;
        eligibleLagValues = topPercP2Prows.lag;
        Xeligible = [ones(size(eligibleP2Pvalues)) eligibleP2Pvalues];
        yhat = Xeligible * b;
        vertical_residuals = abs(eligibleLagValues - yhat);
        pointsIdx = vertical_residuals <= firstLagSpread / 2;
        topPercLags = topPercP2Prows.lag(pointsIdx);
        topPercP2P = topPercP2Prows.P2P(pointsIdx);
        X = [ones(size(topPercP2P)) topPercP2P];
        y = topPercLags;
        % Solve OLS
        b = X \ y;  
        yhat = X * b;
        
    end
    fig = figure;
    scatter(topPercP2P, topPercLags, 'filled');
    hold on;
    plot(topPercP2P, yhat, 'r-', 'LineWidth', 2);
    xlabel('P2P');
    ylabel('Lag');
    title([channel ' Regression of Lag vs. P2P']);
    legend('Data','Fitted line');
    close(fig);
    largestSpikeRegression.(channel).Coefficients = b; % Store the regression coefficients
    largestSpikeRegression.(channel).FirstLagSpread = firstLagSpread; % Store the distance threshold used
end

%% Lowpass filter
processedRow.Lowpass_EMG = EMG_filt(EMG_raw_struct, f, e);

%% Bandpass filter
processedRow.Bandpass_EMG = EMG_filt(EMG_raw_struct, b, a);

%% Shift the bandpassed signal to last reference
[struct_EMG_trials_shift_fromBand, struct_EMG_trials_shiftIDX] = align_signals(processedRow.Bandpass_EMG);
processedRow.AlignedFromBand = struct_EMG_trials_shift_fromBand;
processedRow.AlignedShiftIdxFromBand = struct_EMG_trials_shiftIDX;

%% Rectify the shifted signal
muscleFieldnames = fieldnames(struct_EMG_trials_shift_fromBand);
rectStruct = struct;
for channel_num = 1:numel(muscleFieldnames)
    muscle = muscleFieldnames{channel_num};
    muscles_trials = struct_EMG_trials_shift_fromBand.(muscle);
    rectStruct.(muscle) = abs(muscles_trials);
end
processedRow.Rectified_Shifted = rectStruct;

%% Stimulation onset
struct_stimONSET_INDEX_EMG_trials = getStimOnsetMax(processedRow.Bandpass_EMG);
processedRow.StimOnsetPeaks = struct_stimONSET_INDEX_EMG_trials;

%% Smooth intermediate step before aligning
struct_filtSMOOTH_EMG_trials = Smoothing_wind_Filt(processedRow.Bandpass_EMG, windowDuration, sampleRate);
processedRow.Smoothed = struct_filtSMOOTH_EMG_trials;

%% Shifting signal to last reference
[struct_EMG_trials_shift_fromSmooth, struct_EMG_trials_shiftIDX] = align_signals(struct_filtSMOOTH_EMG_trials);
processedRow.AlignedFromSmoothed = struct_EMG_trials_shift_fromSmooth;
processedRow.AlignedShiftIdxFromSmoothed = struct_EMG_trials_shiftIDX;

%% Rectify the smoothed signal
muscleFieldnames = fieldnames(struct_EMG_trials_shift_fromSmooth);
rectStruct = struct;
for channel_num = 1:numel(muscleFieldnames)
    muscle = muscleFieldnames{channel_num};
    muscles_trials = struct_EMG_trials_shift_fromSmooth.(muscle);
    rectStruct.(muscle) = abs(muscles_trials);
end
processedRow.RectifiedSmoothed_AfterAligned = rectStruct;