function AUC = getAUC(signal, startIDX, endIDX, fs)
% fs - 2000, so 1/2000 = every 0.0005 s
% fs - 1000* 1/fs = .5 ms

	idxArr = startIDX:1:endIDX;
    timeArr_ms = 1000*idxArr/fs; 
    
    sig_portion = signal(startIDX:endIDX);
    AUC = trapz(timeArr_ms, sig_portion);
    % mv*ms 


end