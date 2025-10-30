function [resultTable] = peaksAutoTEPsOneMuscle(muscleData, muscleName, minPeakProm, minPeakHeight, minPeakWidth)

%% PURPOSE: AUTOMATICALLY FIND THE PEAKS IN ONE MUSCLE'S TEPs DATA
% Inputs:
% muscleData: The signal for this muscle's EMG data
% muscleName: Char of the name of the muscle
% minPeakProm: The minimum peak prominence (see findpeaks() docs)
% minPeakHeight: The minimum peak height (see findpeaks() docs)
% minPeakWidth: The minimum peak width (see findpeaks() docs)
%
% Outputs:
% resultTable: 

% numPulses = size(muscleData,1);
% for i = 1:numPulses
%     signal = muscleData(i,:);
%     [minIDX, maxIDX, min_mV, max_mV, p2p, latency, End,  STIM_ARTIFACT_PEAK] =...
%                 peaksAuto(signal, foundLat, minIDX_picked, maxIDX_picked, sitmIDX_picked);
% end

resultTable = table;

%% Plot the data
numTotalPulses = size(muscleData,1);
colors = getColorMap(numTotalPulses);
% ax1 = subplot(3,1,1);
% hold on;
% ax2 = subplot(3,1,2);
% hold on;
% ax3 = subplot(3,1,3);
% hold on;
% for pulseNum = numTotalPulses:-1:1
%     signal = muscleData(pulseNum,:);
%     currentColor = colors(pulseNum,:);
%     plot(ax1, signal, 'Color', currentColor);    
%     signalDeriv = [NaN, diff(signal)];
%     plot(ax2, signalDeriv, 'Color', currentColor);
%     signalDeriv2 = [NaN, diff(signalDeriv)];
%     plot(ax3, signalDeriv2, 'Color', currentColor);
% end
% ylabel(ax1, 'EMG Signal');
% ylabel(ax2, 'First Derivative');
% ylabel(ax3, 'Second Derivative');
% ylim(ax1, [-5, 5]);
% return;

%% Find which pulse has the largest absolute value
[minValsPerPulse, minIdxPerPulse] = min(muscleData, [], 2);
[largestMinPulseVal, largestMinPulseIdx] = max(abs(minValsPerPulse)); % Find which pulse has the largest min
[maxValsPerPulse, maxIdxPerPulse] = max(muscleData, [], 2);
[largestMaxPulseVal, largestMaxPulseIdx] = max(abs(maxValsPerPulse));

if largestMinPulseVal >= largestMaxPulseVal
    largestPulseIdx = largestMinPulseIdx;
else
    largestPulseIdx = largestMaxPulseIdx;
end

% Pull out the data for the largest pulse.
largestPulseData = muscleData(largestPulseIdx,:);

%% 2/14 trying new algorithm
fig = figure('Name',muscleName);
plot(largestPulseData);
peaksIdx = diff([NaN, sign([NaN, diff(largestPulseData)])])~=0; % The logical idx of all the peaks
peaksIdxNum = find(peaksIdx);
peaksIdxNum = peaksIdxNum(3:end)-1; % Numeric indices of the peaks
% REMOVE THE PEAKS WHERE THE SIGNAL DOESN'T CROSS ZERO BETWEEN THEM.
crossZeroUnsortedPeaks = [];
addPrev = true;
for i = 1:length(peaksIdxNum)
    prevPeakVal = NaN;
    prevPeakIdx = NaN;
    nextPeakVal = NaN;
    nextPeakIdx = NaN;
    currPeakVal = largestPulseData(peaksIdxNum(i));
    currPeakIdx = peaksIdxNum(i);    

    if i >= 2
        prevPeakVal = largestPulseData(peaksIdxNum(i-1));
        prevPeakIdx = peaksIdxNum(i-1);
    end
    if isnan(prevPeakIdx)
        prevPeakVal = -1*currPeakVal; % Ensure a zero crossing
    end
    
    if i < length(peaksIdxNum)
        nextPeakVal = largestPulseData(peaksIdxNum(i+1));
        nextPeakIdx = peaksIdxNum(i+1);
    end    
    if isnan(nextPeakIdx)
        nextPeakVal = -1*currPeakVal; % Ensure a zero crossing
    end

    if min([currPeakVal, nextPeakVal]) < 0 && max([currPeakVal, nextPeakVal]) > 0 ...
            && min([prevPeakVal, currPeakVal]) < 0 && max([prevPeakVal, currPeakVal]) > 0        
        newToAdd = [prevPeakIdx; currPeakIdx; nextPeakIdx];
        if ~addPrev
            newToAdd = newToAdd(2:end);
        end
        newToAdd(isnan(newToAdd) | ismember(newToAdd, crossZeroUnsortedPeaks)) = [];
        crossZeroUnsortedPeaks = [crossZeroUnsortedPeaks; newToAdd];
        addPrev = true;
    else
        addPrev = false;
    end
end
peaksVals = largestPulseData(crossZeroUnsortedPeaks); % The values of the peaks
peakValDiffs = [NaN, diff(peaksVals)]; % The y diff between neighboring peaks
[~,k] = sort(abs(peakValDiffs),'descend');
sortedPeaksByMagIdxNum = crossZeroUnsortedPeaks(k(2:end)); % The sorted indices of the end of the ranges of largest y diffs
largestNeighbors = sortedPeaksByMagIdxNum(1);
for i = 2:length(sortedPeaksByMagIdxNum)-1
    prevIdx = sortedPeaksByMagIdxNum(i-1);
    nextIdx = sortedPeaksByMagIdxNum(i);
    if any(sortedPeaksByMagIdxNum(i+1:end) > min([prevIdx, nextIdx]) & sortedPeaksByMagIdxNum(i+1:end) < max([prevIdx, nextIdx]))
        break;
    end
    largestNeighbors = [largestNeighbors; nextIdx];
end
hold on;
scatter(largestNeighbors, largestPulseData(largestNeighbors), 'r*');
firstMuscleActivationPeak = min(largestNeighbors);
close(fig);
return;








%% Find the peaks of muscle activation for the largest pulse.
minPeakHeight = 0.3;
minPeakProm = minPeakHeight;
minPeakWidth = 5;
[peakVals, peakIdx] = findpeaks(largestPulseData,'MinPeakProminence',minPeakProm,'MinPeakHeight',minPeakHeight,'MinPeakWidth',minPeakWidth);
[valleyVals, valleyIdx] = findpeaks(-1*largestPulseData,'MinPeakProminence',minPeakProm,'MinPeakHeight',minPeakHeight,'MinPeakWidth',minPeakWidth);
valleyVals = -1*valleyVals;
% fig = figure('Name',muscleName);
% plot(largestPulseData);
% hold on;
% scatter(peakIdx, peakVals,'k','filled');
% scatter(valleyIdx, valleyVals, 'k','filled');


%% Get the onset of muscle activation by:
% Step 1: Looking backward from the first peak to the first time that the derivative changes sign.
% Because this tends to be too conservative (looks too far back), I use
% this as a bookend for step 2.
firstPeakIdx = min([peakIdx, valleyIdx]);
deriv = [NaN, diff(largestPulseData)];
firstPeakSign = sign(diff(largestPulseData(firstPeakIdx-1:firstPeakIdx)));
derivChangeIdxBeforePeak = find(sign(deriv(1:firstPeakIdx))==-1*firstPeakSign,1,'last');

% Step 2: Between the first peak idx and the idx from step 1, find the point
% where a three-point circle of best fit has the smallest radius.
idxVector = derivChangeIdxBeforePeak:firstPeakIdx;
[activationRadii, activationCenters] = getCircles(idxVector, largestPulseData);
if firstPeakSign==1
    circleCorrectSideIdx = activationCenters(:,2) > largestPulseData(idxVector)';
elseif firstPeakSign==-1
    circleCorrectSideIdx = activationCenters(:,2) < largestPulseData(idxVector)';
end
[~, minRadiusIdxActivation] = min(activationRadii(circleCorrectSideIdx));
idxNums = find(circleCorrectSideIdx==1,minRadiusIdxActivation,'first');
activationOnsetIdxNum = idxVector(idxNums(end))-2;

%% To get the stimulation artifact onset, follow a similar method as above for the data before muscle activation onset.
largestPulseDataBeforeActivation = largestPulseData(1:activationOnsetIdxNum-1);
minPeakHeight = 0.01;
minPeakProm = 0.04;
minPeakWidth = 2;
[peakVals, peakIdx] = findpeaks(largestPulseDataBeforeActivation,'MinPeakProminence',minPeakProm,'MinPeakHeight',minPeakHeight,'MinPeakWidth',minPeakWidth);
[valleyVals, valleyIdx] = findpeaks(-1*largestPulseDataBeforeActivation,'MinPeakProminence',minPeakProm,'MinPeakHeight',minPeakHeight,'MinPeakWidth',minPeakWidth);
valleyVals = -1*valleyVals;
scatter(peakIdx, peakVals,'b','filled');
scatter(valleyIdx, valleyVals, 'b','filled');

%% Get the onset of stim by looking backward from the first peak to the first time that the derivative changes sign.
% Step 1
stimPeakIdx = min([peakIdx, valleyIdx]);
stimPeakSign = sign(diff(largestPulseDataBeforeActivation(stimPeakIdx-1:stimPeakIdx)));
derivChangeIdxBeforeStim = find(sign(deriv(1:stimPeakIdx))==-1*stimPeakSign,1,'last');
% Step 2
idxVectorStim = derivChangeIdxBeforeStim:stimPeakIdx;
[stimRadii, stimCenters] = getCircles(idxVectorStim, largestPulseData(1:activationOnsetIdxNum));
if stimPeakSign==1
    circleCorrectSideIdx = stimCenters(:,2) > largestPulseData(idxVectorStim)';
elseif stimPeakSign==-1
    circleCorrectSideIdx = stimCenters(:,2) < largestPulseData(idxVectorStim)';
end
[~, minRadiusIdxStim] = min(stimRadii(circleCorrectSideIdx));
idxNums = find(circleCorrectSideIdx==1,minRadiusIdxStim,'first');
stimOnsetIdxNum = idxVectorStim(idxNums(end));

resultTable.StimOnsetIdx = stimOnsetIdxNum;
resultTable.MuscleActivationOnsetIdx = activationOnsetIdxNum;

%% Get the power spectrum of the largest pulse data
% demeaned = largestPulseData - mean(largestPulseData);
% % Calculate FFT
% N = length(demeaned);
% Y = fft(demeaned);
% % Calculate two-sided power spectrum
% P2 = abs(Y/N).^2;
% % Convert to single-sided power spectrum
% P1 = P2(1:floor(N/2)+1);
% P1(2:end-1) = 2*P1(2:end-1);
% 
% % Create frequency vector
% frequencies = 2000 * (0:(N/2))/N;
% % Store power spectrum
% power_spectrum = P1;
% % Find peaks in power spectrum
% [pks, locs] = findpeaks(power_spectrum, 'SortStr', 'descend');
% % Get frequencies of top peaks
% dominant_freqs = frequencies(locs);
% % plot(frequencies, power_spectrum);
% 
% %% Plot a heatmap of the frequency domain over time
% fig = figure;
% subplot(3,1,1);
% demeaned = largestPulseData - mean(largestPulseData);
% window_size = 10;
% window = hann(window_size);
% overlap = 0.75;
% noverlap = round(window_size * overlap);
% [S, F, T] = spectrogram(demeaned, window, noverlap, [], 2000, 'yaxis');
% S = abs(S).^2;
% freq_cutoff = 450;
% freq_mask = F <= freq_cutoff;
% avg_power = mean(S(freq_mask, :), 1);
% % Initialize peak_freqs array
% peak_freqs = zeros(size(T));
% % For each time point, find the frequency with maximum power
% for t = 1:size(S, 2)
%     % Get power spectrum for this time point, considering only frequencies below cutoff
%     power_spectrum = S(freq_mask, t);
%     freqs = F(freq_mask);
% 
%     % Find the frequency with maximum power
%     [~, max_idx] = max(power_spectrum);
%     peak_freqs(t) = freqs(max_idx);
% end
% imagesc(T, F, 10*log10(S));
% axis xy;  % Put zero frequency at bottom
% colormap(jet);  % Use jet colormap for better frequency visualization
% c = colorbar;
% c.Label.String = 'Power/Frequency (dB/Hz)';
% xlabel('Time (s)');
% ylabel('Frequency (Hz)');
% title('Spectrogram');
% 
% % Adjust colormap limits for better contrast
% clim([max(10*log10(S(:))) - 60, max(10*log10(S(:)))]);
% 
% subplot(3,1,2);
% plot(peak_freqs, 'LineWidth', 2);
% xlabel('Time (s)');
% ylabel('Freq with Maximum Power');
% title('Peak Frequency Over Time');
% 
% %% Plotting
% % fig = figure('Name', muscleName);
% subplot(3,1,3);
fig.WindowState = 'maximized';
plot(largestPulseData,'k');
hold on;
title([muscleName ': Red = Stim Onset, Green = Muscle Activation Onset']);
ylabel('mV');
xlabel('Time (indices)');
xline(activationOnsetIdxNum,'g');
xline(stimOnsetIdxNum,'r');
close(fig);
end

function [radii, centers] = getCircles(idxVector, dataVector)

radii = NaN(length(idxVector),1);
centers = NaN(length(radii),2);
for i = 1:length(idxVector)-2
    x = idxVector(i:i+2);
    y = dataVector(x);
    % Create coefficient matrix A
    A = [2*(x(2)-x(1)) 2*(y(2)-y(1));
         2*(x(3)-x(1)) 2*(y(3)-y(1))];
     
    % Create constant vector b
    b = [(x(2)^2 + y(2)^2 - x(1)^2 - y(1)^2);
         (x(3)^2 + y(3)^2 - x(1)^2 - y(1)^2)];
     
    % Solve for center coordinates
    centers(i,:) = A\b;
    h = centers(i,1);
    k = centers(i,2);
    
    % Calculate radius using any of the points
    radii(i) = sqrt((x(1)-h)^2 + (y(1)-k)^2);
end

end

function [cmap] = getColorMap(numColors)

%% PURPOSE: CREATE A COLORMAP BASED ON TURBO WITH A CUSTOM NUMBER OF COLORS.

% Get the default turbo colormap
originalTurbo = turbo;

% Create interpolation points
x = linspace(1, size(originalTurbo,1), numColors);
xi = 1:size(originalTurbo,1);

% Interpolate each RGB channel
cmap = interp1(xi, originalTurbo, x);
end