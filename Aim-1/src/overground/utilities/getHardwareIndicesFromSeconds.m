function [indicesStruct] = getHardwareIndicesFromSeconds(secondsStruct, fs)

%% PURPOSE: CONVERT A STRUCT OF GAIT EVENTS, GAIT PHASE ONSET & TERMINATION, AND GAIT PHASE DURATIONS FROM SECONDS TO SAMPLES
% secondsStruct fields: gaitEvents, gaitPhases, gaitPhasesDurations

indicesStruct = struct;
secondsStructFieldNames = fieldnames(secondsStruct);
numDigits = length(num2str(fs));
for i = 1:length(secondsStructFieldNames)
    fieldName = secondsStructFieldNames{i};
    indicesStruct.(fieldName) = struct;

    subFieldNames = fieldnames(secondsStruct.(fieldName));
    for j = 1:length(subFieldNames)
        subFieldName = subFieldNames{j};
        indicesStruct.(fieldName).(subFieldName) = round(round(secondsStruct.(fieldName).(subFieldName), numDigits-1) .* fs); % Second round is to remove the zeros (and approximation errors?)
        noNaNVals = indicesStruct.(fieldName).(subFieldName);
        noNaNVals(isnan(noNaNVals)) = [];
        if ~all(rem(noNaNVals,1)==0)
            error('Not whole-number indices');
        end
    end

end