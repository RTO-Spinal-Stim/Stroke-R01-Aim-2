function [varargout] = parseFileName(regexsConfig, fileName)

%% PURPOSE: PARSE A FILE NAME TO OBTAIN THE CONDITIONS
% Inputs:
% regexsConfig: The config struct for regexs
% fileName: Char for the file name
%
% Outputs:
% varargout: Cell array of the parsed name components.

[~, subject_id] = findPatternIndices(fileName, regexsConfig.SUBJECT_ID);
[~, intervention_name] = findPatternIndices(fileName, regexsConfig.INTERVENTIONS);
[~, speed] = findPatternIndices(fileName, regexsConfig.SPEED);
[~, trial] = findPatternIndices(fileName, regexsConfig.TRIAL);

nameComponents = {subject_id, intervention_name, speed, trial};

if nargout == 1
    varargout{1} = nameComponents;
else
    varargout = nameComponents;
end