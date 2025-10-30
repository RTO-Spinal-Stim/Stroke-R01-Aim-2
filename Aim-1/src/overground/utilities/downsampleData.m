function [downsampledData] = downsampleData(data, n_points_new)

%% PURPOSE: DOWNSAMPLE THE DATA TO THE SPECIFIED NUMBER OF POINTS.

fieldNames = fieldnames(data);
for i = 1:length(fieldNames)
    fieldName = fieldNames{i};
    n_points_original = length(data.(fieldName));
    downsampledData.(fieldName) = [];
    if ~isempty(data.(fieldName)) % Will be empty if on last gait cycle of one side, and that side has more gait cycles than the other.
        downsampledData.(fieldName) = resample(data.(fieldName), n_points_new, n_points_original);
    end
    if size(downsampledData.(fieldName),1) > 1
        downsampledData.(fieldName) = downsampledData.(fieldName)';
    end
end