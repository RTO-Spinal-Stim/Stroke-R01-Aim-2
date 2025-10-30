function [index, matchedPattern] = findPatternIndices(inputStr, patterns)

%% PURPOSE: FIND THE PART OF THE FILE NAME MATCHING THE PRE-DEFINED PATTERNS.
% patterns: 1xN cell array of regex chars

if ~iscell(patterns)
    patterns = {patterns};
end

% Loop through each pattern
for i = 1:length(patterns)
    % Find all matches for current pattern
    [index, ~, matchedPattern] = regexp(inputStr, patterns{i}, 'start', 'end', 'match');

    % Add any matches found to our results
    if ~isempty(index)
        assert(length(index)==1);
        matchedPattern = matchedPattern{1};
        return;
    end
end