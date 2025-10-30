function [minIDX, maxIDX, min_mV, max_mV, p2p, latency, End] = peaksAuto(signal, foundLat, minIDX_picked, maxIDX_picked)

if isnan(foundLat) & isnan(minIDX_picked) & isnan(maxIDX_picked)
    minIDX= NaN;
    maxIDX= NaN; 
    min_mV= NaN; 
    max_mV= NaN; 
    p2p= NaN; 
    latency= NaN;
    End = NaN;
    return
end

if isnan(foundLat) 
    minIDX= NaN;
    maxIDX= NaN; 
    min_mV= NaN; 
    max_mV= NaN; 
    p2p= NaN; 
    latency= NaN;
    End = NaN;
    return
end

End = foundLat+100;

% sometimes latency might be past the end of the signal - so 
if End > length(signal)
    End = length(signal); 
end

%%
% Without double checking
% % MAX
% % Find local extrema points between clicked latency and 100 indeces after
% extrema_indices = find(diff(sign(diff(signal(foundLat:End)))) == -2) + 1;
% % Correct so it is in the time signal index scale
% extrema_indices = extrema_indices + foundLat;
% 
% % Find the largest peak as the MEP start (from the "extrema" found above)
% [~, max_peak_index] = max(signal(extrema_indices));
% maxIdx = extrema_indices(max_peak_index);
% 
% % Find the corresponding minimum and maximum values
% maxPeak = signal(maxIdx);
% 
% % MIN
% min_extrema_indices = find(diff(sign(diff(-1*signal(foundLat:End)))) == -2) + 1;
% % Correct so it is in the time signal index scale
% min_extrema_indices = min_extrema_indices + foundLat;
% 
% [~, min_peak_index] = min(signal(min_extrema_indices));
% minIdx = min_extrema_indices(min_peak_index);
% minPeak = signal(minIdx);
% %% Find the peak of stim artifact
% 
% % Max Peak 
% % room to find - within 25 
% within_lookup = 25; 
% MAX_LOOKUP= 55; 
%                 
% if stim_onset_max_REFERENCE <= 25
%     within_lookup = stim_onset_max_REFERENCE-1;
% end
% 
% % End look up should be MAX_LOOKUP
% end_lookup = stim_onset_max_REFERENCE+25;
% if stim_onset_max_REFERENCE+25 > MAX_LOOKUP
%    end_lookup = MAX_LOOKUP;
% end
% 
% 
% approx_signal_artifact = diff(signal(stim_onset_max_REFERENCE - within_lookup: end_lookup));
% 
% 
% 
% 
% [pks, locs] = findpeaks(approx_signal_artifact);
% [maxPeak, idx] = max(pks);
% stim_onset_max = locs(idx)+ stim_onset_max_REFERENCE - within_lookup;


%% Double check - that min/max index selected is the closest one.

%MAX
extrema_indices = find(diff(sign(diff(signal(foundLat:End)))) == -2) ;
% Correct so it is in the time signal index scale
extrema_indices = extrema_indices + foundLat;

% Check that the possible indices are within 30 indices of the "found"
revised_max_idxs = extrema_indices(extrema_indices <= maxIDX_picked+25 & extrema_indices >= maxIDX_picked-25); 

% Find the largest peak as the MEP start (from the "extrema" found above)
% WITH NO REVISION [~, max_peak_index] = max(signal(extrema_indices));
[~, max_peak_index] = max(signal(revised_max_idxs));
maxIdx = revised_max_idxs(max_peak_index);

% Find the corresponding minimum and maximum values
maxPeak = signal(maxIdx);

% MIN
min_extrema_indices = find(diff(sign(diff(-1*signal(foundLat:End)))) == -2) ;
% Correct so it is in the time signal index scale
min_extrema_indices = min_extrema_indices + foundLat;

% Check that the possible indices are within 30 indices of the "found"
revised_min_idxs = min_extrema_indices(min_extrema_indices <= minIDX_picked+25 & min_extrema_indices >= minIDX_picked-25); 

[~, min_peak_index] = min(signal(revised_min_idxs));
minIdx = revised_min_idxs(min_peak_index);
minPeak = signal(minIdx);

%%
% Find Latency and End
% Latency has to be close to the peak found - 


mep_signal = signal;

derivative_signal = diff(mep_signal);

% Set a threshold to determine significant deviation from zero
threshold = 3*std(derivative_signal(1:10));  % Adjust this threshold as needed

% Find the index where the derivative first exceeds the threshold
latency_possible_IDX = find(abs(derivative_signal(foundLat-20:foundLat+20)) > threshold);
gaps = find(diff(latency_possible_IDX) > 1); % Find where the difference between consecutive elements is greater than 1

if ~isempty(gaps)
    latency = latency_possible_IDX(gaps(1) + 1); % Get the first non-continuous index
    latency = latency +foundLat-20;
    % Identify end point based on derivative slope change after index 120

    End = latency+100;
else
    latency = foundLat; % No non-continuous index found
end



%%
% Quality check - check that latency is before the peak to peaks found:
if isempty(maxIdx) || isempty(minIdx) || isempty(latency) % no min or max found:
    latency = NaN;
    End = NaN;
elseif minIdx < latency || maxIdx < latency
   latency = NaN;
   End = NaN;
end 
if End > 185 % exceeds the end of the signal. 
   latency = NaN;
   End = NaN;
end
                   

%%


p2p = abs(maxPeak - minPeak); % if one of them is NaN - then 

% There has to be a peak and a latency for us to call this a mep. 
    if p2p >= 0.03 
        minIDX = minIdx;
        maxIDX = maxIdx;
        min_mV = minPeak;
        max_mV = maxPeak;
        
        if isempty(latency)
            % found a peak to peak - but not a latency
            latency = foundLat;
            End = foundLat+100;
            flagged = 1;
        else
            flagged = NaN;
            % AND THE LATENCY AND END IS THE FOUND LATENCY FROM ABOVE
        end
        
    else
      
        p2p = NaN;
        minIDX = NaN;
        maxIDX = NaN;
        min_mV = NaN;
        max_mV = NaN;
        latency = NaN;
        End = NaN;
        flagged = NaN;
    end
    
 

end