% Signal to shift comes later - should be postive lag
sig_toShift = [0,0,0,1,0,0,0,0];
ref_sig = [0,0,1,0,0,0,0,0];
% Compute cross-correlation
[crossCorr, lags] = xcorr(sig_toShift, ref_sig);


% Find the index of the maximum correlation
[~, maxIndex] = maxk(crossCorr,1);

% Compute the lag between the signals
lagDiff = lags(maxIndex);

alignedSignal = zeros(size(sig_toShift));



shift_index = lagDiff;

figure
subplot(3,1,1)
plot(ref_sig)
hold on;
plot(sig_toShift)
hold on;
xline(maxIndex-length(sig_toShift))
legend("ref", "sig")
title(["shift index " + shift_index]);

% Shift left and fill the rest with zeros
%A positive lag means the sig_toShift needs to be shifted forward (delayed) to align with ref_sig, 
%and a negative lag means sig_toShift should be shifted backward (advanced).

if lagDiff< 0
    s = abs(lagDiff);
    alignedSignal(s+1:end) = sig_toShift(1:end-s);
    % shifts to right or forward
else
    alignedSignal(1:end-lagDiff) = sig_toShift(lagDiff+1:end);
    % shifts to left - moving back the amount of
    % lagDiff
end 

subplot(3,1,2)
plot(alignedSignal)
hold on
plot(sig_toShift)
hold on;
legend("shifted", "sig")

subplot(3,1,3)
plot(alignedSignal)
hold on
plot(ref_sig)
hold on;
legend("shifted", "ref")


% max index 

multi_signals = alignedSignal.*ref_sig; 
[~, maxIndex_alignedSigs] = maxk(multi_signals,1);
disp(maxIndex_alignedSigs)


%%
% Cross correlation example:

sig_toShift = [0, 0, 0, 1, 0, 0, 0, 0];
x_shift = [-7,-6,-5,-4,-3,-2,-1,0];

ref_sig = [0, 0, 0, 0, 0, 0, 1, 0];
ref_index = [0,1,2,3,4,5,6,7];



[crossCorr, lags] = xcorr(sig_toShift, ref_sig);


% Find the index of the maximum correlation
[~, maxIndex] = maxk(crossCorr,1);

% Compute the lag between the signals
lagDiff = lags(maxIndex);

figure
plot(sig_toShift, 'r')
hold on
plot(ref_sig, 'b')
legend('toshift','ref')
title(lagDiff)

alignedSignal = zeros(size(sig_toShift));



shift_index = lagDiff;

figure
h = gobjects(1, length(sig_toShift)); % Initialize array for storing subplot handles
plot(x_shift,sig_toShift, 'r--', 'LineWidth', 1.5)
hold on
plot(ref_index,ref_sig, 'color', 'blue')
figure
for i = 1:length(lags)
    
    h(i)=subplot(length(lags),1,i);
    ref_index_shift = ref_index+lags(i);
    disp(ref_index_shift);
    
    plot(ref_index_shift, ref_sig, 'r--', 'LineWidth', 1.5)
    hold on
    plot(ref_index, sig_toShift, 'b')
end
% Link the x-axes of all subplots
linkaxes(h, 'x');



