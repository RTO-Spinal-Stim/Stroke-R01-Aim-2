function [tableOut] = maxEMGValuePerVisit(dataTable, emgColName, maxEMGColName, MVC_MUSCLE_MAPPING)
%% PURPOSE: Find the max EMG per mapped channel (e.g., LTA, LVL, RRF, etc.)
% Inputs:
%   dataTable: Table where each row is one trial or gait cycle.
%   emgColName: The column name for the EMG data (struct with EMG fields).
%   maxEMGColName: Name of output column with max EMG struct.
%   MVC_MUSCLE_MAPPING: Struct where each field = group name in dataTable.Muscle
%                       and each value = char/cell array of EMG channel names.
%
% Outputs:
%   tableOut: Table where each row corresponds to one unique Subject+Intervention,
%             with max EMG value per mapped channel.

disp('Getting the max EMG value per mapped muscle per visit');

%% Get unique Subject+Intervention combos
uniqueVisitsTable = unique(dataTable(:, {'Subject','Intervention'}), 'rows', 'stable');
tableOut = uniqueVisitsTable;
tableOut.(maxEMGColName) = repmat({struct}, height(uniqueVisitsTable), 1);

%% Build master list of all channels mentioned in mapping
canonicalChannels = {};
mapFields = fieldnames(MVC_MUSCLE_MAPPING);
for f = 1:numel(mapFields)
    vals = MVC_MUSCLE_MAPPING.(mapFields{f});
    if ischar(vals), vals = {vals}; end
    if isstring(vals), vals = cellstr(vals); end
    canonicalChannels = [canonicalChannels; vals(:)];
end
canonicalChannels = unique(canonicalChannels);

%% Iterate over each visit
for visitNum = 1:height(uniqueVisitsTable)
    visitRow = uniqueVisitsTable(visitNum,:);
    
    % Rows for this Subject + Intervention
    visitRowsIdx = ismember(dataTable.Subject, visitRow.Subject) & ...
                   ismember(dataTable.Intervention, visitRow.Intervention);
    currDataTable = dataTable(visitRowsIdx, :);
    
    % Initialize struct with -inf
    maxEMGStruct = struct();
    for m = 1:numel(canonicalChannels)
        maxEMGStruct.(canonicalChannels{m}) = -inf;
    end
    
    % Loop over trials in this visit
    for i = 1:height(currDataTable)
        emgData = currDataTable.(emgColName)(i);   % struct of EMG signals
        
        % Normalize group name
        muscleGroup = currDataTable.Muscle(i);
        if iscell(muscleGroup), muscleGroup = muscleGroup{1}; end
        if isstring(muscleGroup), muscleGroup = char(muscleGroup); end
        if iscategorical(muscleGroup), muscleGroup = char(muscleGroup); end
        
        % Lookup channels for this group
        if isfield(MVC_MUSCLE_MAPPING, muscleGroup)
            mappedChannels = MVC_MUSCLE_MAPPING.(muscleGroup);
            if ischar(mappedChannels), mappedChannels = {mappedChannels}; end
            if isstring(mappedChannels), mappedChannels = cellstr(mappedChannels); end
            
            % Update each channel independently
            for c = 1:numel(mappedChannels)
                chan = strtrim(mappedChannels{c});
                if isfield(emgData, chan)
                    trialMax = max(emgData.(chan), [], 'omitnan');
                    maxEMGStruct.(chan) = max([maxEMGStruct.(chan), trialMax], [], 'omitnan');
                else
                    continue;
                end
            end
        else
            continue;
        end
    end
    
    % Replace -inf with NaN for channels never updated
    for m = 1:numel(canonicalChannels)
        if isinf(maxEMGStruct.(canonicalChannels{m}))
            maxEMGStruct.(canonicalChannels{m}) = NaN;
        end
    end
    
    % Save result
    tableOut.(maxEMGColName){visitNum} = maxEMGStruct;
end
end
