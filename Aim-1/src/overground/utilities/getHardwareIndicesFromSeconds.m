function indicesStruct = getHardwareIndicesFromSeconds(secondsStruct, fs)

% PURPOSE:
% Convert gait events given in ABSOLUTE seconds into sample indices for EMG/IMU
% where EMG fs = 2000 and IMU fs = 100 share the same hardware time sync.

indicesStruct = struct;
fields = fieldnames(secondsStruct);

for f = 1:length(fields)
    fieldName = fields{f};
    indicesStruct.(fieldName) = struct;

    subFields = fieldnames(secondsStruct.(fieldName));

    for s = 1:length(subFields)
        subField = subFields{s};

        t = secondsStruct.(fieldName).(subField);

        % Convert seconds → samples (global clock → sample index)
        idx = round(t * fs);

        % Preserve NaNs
        idx(isnan(t)) = NaN;

        % Store
        indicesStruct.(fieldName).(subField) = idx;

        % Verify no float drift
        nonNaN = idx(~isnan(idx));
        if ~all(rem(nonNaN,1) == 0)
            error('Non-integer sample index — check time sync precision.');
        end
    end
end
