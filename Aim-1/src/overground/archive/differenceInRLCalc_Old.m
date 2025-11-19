function RLdifference = differenceInRLCalc_Old(SPM, average)

%% PURPOSE: CALCULATE THE DIFFERENCE IN R & L AMPLITUDE, AND THE DURATION OF THAT DIFFERENCE

SPMfields = fieldnames(SPM);

for i = 1:numel(SPMfields)
    %extract SPM difference bounds
    endpoints = round(SPM.(SPMfields{i}).endpoints);
    
    if endpoints(1,1) == 0 && endpoints(1,2) == 0
        %if no difference, make 0
        RLdifference.amplitude.(SPMfields{i}) = 0;
        RLdifference.duration.(SPMfields{i}) = 0;
        
    else
        
        endpoints = endpoints + 1;
                
        for j = 1:length(endpoints(:,1))
            %calculate difference in R-L amplidtude and duration length
            amp(j) = abs(mean(average.left.(SPMfields{i})(endpoints(j,1):endpoints(j,2))) - mean(average.right.(SPMfields{i})(endpoints(j,1):endpoints(j,2))));
            dur(j) = abs(endpoints(j,2) - endpoints(j,1));
            
        end
        %if there are several durations that are different, average
        %amplitude and add duration
        RLdifference.amplitude.(SPMfields{i}) = mean(amp);
        RLdifference.duration.(SPMfields{i}) = sum(dur);
        
        clear dur amp
    end
    
end