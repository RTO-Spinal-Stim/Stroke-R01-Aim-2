% Smers pipeline pre preocessing:
% From Labchart exported .mat file
% FILL IN BAD PULSES IN TEPS_LOG.xlsx
% To struct containing:
% - Raw segmented time signal per trial
% Filtered
% Centered and demeaned (After filtered)
% Aligned/shifted ( sometimes the delsys sends the trigger late ~45
% points, 22 ms)
% Saved to participant

% Create folder to save mats if do not exist
% Define the new folder path
