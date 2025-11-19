function [resultsTable] = patternMatchMEP(dataRaw, pulseNum)

%% PURPOSE: PATTERN MATCH TO TRY TO DETERMINE IF THERE'S A MEP IN THE DATA
% Inputs:
% dataRaw: Timeseries of one pulse of one muscle (1x200 double)
% pulseNum: The pulse number (count)
%
% Outputs:
% resultsTable: Return the computed MEP features, if any

%% Initialize outputs
resultsTable = table;

%% Initialize settings
minP2PThresh = 0.05; % Minimum peak 2 peak amplitude for a MEP
data = dataRaw - mean(dataRaw); % Demean the data
maxY = max(abs(data)); % Get the largest absolute value
num_amplitudes = 20;
p2p_amplitudes = linspace(minP2PThresh, maxY, num_amplitudes); % The peak to peak amplitude values
min_mep_period = 5; % The minimum duration number of points for a sine wave to be a MEP
max_mep_period = 40; % The maximum duration number of points for a sine wave to be a MEP
period_step = 1; % How much to change the period between iterations
num_mep_periods = (max_mep_period - min_mep_period)/period_step; % Number of points to check
mep_periods = linspace(min_mep_period, max_mep_period, num_mep_periods);

%% First, check if anything has a P2P amplitude of `minP2P`
% Find out where the peaks are
maxP2PValue = abs(max(data) - min(data));
% peak_indices = [];
% first_deriv = [NaN diff(data)];
% for i = 3:length(first_deriv)
%     if sign(first_deriv(i)) == sign(first_deriv(i-1))
%         continue;
%     end
%     peak_indices = [peak_indices; i];
% end
% exceedsMinP2P = false;
% exceedsMinP2Pidx = [];
% for i = 1:length(peak_indices)-1
%     curr_peak_idx = peak_indices(i);
%     curr_peak_value = data(curr_peak_idx);
%     next_peak_idx = peak_indices(i+1);
%     next_peak_value = data(next_peak_idx);
%     if abs(next_peak_value - curr_peak_value) > minP2P
%         exceedsMinP2P = true;
%         exceedsMinP2Pidx = [exceedsMinP2Pidx; [curr_peak_idx, next_peak_idx]];
%     end
% end
if maxP2PValue < minP2PThresh
    exceedsMinP2P = false;
else
    exceedsMinP2P = true;
end

% No P2P large enough
if ~exceedsMinP2P
    resultsTable = table;
    return;
end

%% Iterate over each period & amplitude combination to match a MEP
% Ensure that the matched regions have > minP2P
for periodNum = 1:length(mep_periods)
    mep_period = round(mep_periods(periodNum));
    for ampNum = 1:length(p2p_amplitudes)
        p2pamplitude = p2p_amplitudes(ampNum);
        % Construct the sine wave to match
        thetas = linspace(0, 2*pi, mep_period);
        sinYValues = (p2pamplitude/2)*sin(thetas);
        mep_period_delta = mep_period - 1;
        % Run the cross-correlation
        maxIdx = length(data) - (mep_period - 1);
        r2_pos = NaN(maxIdx,1);
        r2_neg = NaN(maxIdx,1);
        for i = 1:maxIdx
            yActual = data(i:i+mep_period_delta);            
            ss_tot = sum(yActual.^2);
            ss_res_pos = sum((yActual - sinYValues).^2);
            r2_pos(i) = 1 - (ss_res_pos / ss_tot);
            ss_res_neg = sum((yActual - (-1*sinYValues)).^2);
            r2_neg(i) = 1 - (ss_res_neg / ss_tot);            
        end
        if max(r2_pos) > max(r2_neg)
            r2 = r2_pos;
            r_sign = 1;
        else
            r2 = r2_neg;
            r_sign = -1;
        end
        [maxR2,lag] = max(r2);
        % Compute the P2P from the data signal (rather than template P2P)
        data_section = data(lag:lag+mep_period_delta);
        dataP2P = range(data_section);
        % Record the values
        tmpTable = table;
        tmpTable.P2P = p2pamplitude;
        tmpTable.MEP_Period = mep_period;
        tmpTable.R2 = maxR2;
        tmpTable.lag = lag;        
        tmpTable.Sign = r_sign;  
        tmpTable.DataP2P = dataP2P;
        resultsTable = [resultsTable; tmpTable];
    end
end

