function [tableOut] = addStimNoStim_Intensity_FrequencyCols(tableIn, intColName)

%% PURPOSE: ADD COLUMNS TO THE TABLE INDICATING STIM/NO STIM, INTENSITY, AND FREQUENCY
% Helps with machine learning classifications
% Inputs:
% tableIn: Table with the data
% intColName: Intervention column name
%
% Outputs:
% tableOut: Table with the added columns

ints.RMT30.IS_STIM = "STIM";
ints.RMT30.FREQ = 30;
ints.RMT30.INTENSITY = "RMT";

ints.RMT50.IS_STIM = "STIM";
ints.RMT50.FREQ = 50;
ints.RMT50.INTENSITY = "RMT";

ints.TOL30.IS_STIM = "STIM";
ints.TOL30.FREQ = 30;
ints.TOL30.INTENSITY = "TOL";

ints.TOL50.IS_STIM = "STIM";
ints.TOL50.FREQ = 50;
ints.TOL50.INTENSITY = "TOL";

ints.SHAM1.IS_STIM = "NOSTIM";
ints.SHAM1.FREQ = 0;
ints.SHAM1.INTENSITY = "SHAM";

ints.SHAM2.IS_STIM = "NOSTIM";
ints.SHAM2.FREQ = 0;
ints.SHAM2.INTENSITY = "SHAM";

tableOut = tableIn;

tableOut.Is_Stim = repmat("", height(tableOut), 1);
tableOut.Frequency = repmat("", height(tableOut), 1);
tableOut.Intensity = repmat("", height(tableOut), 1);

for i = 1:height(tableIn)
    intervention = char(tableIn.(intColName)(i));
    tableOut.Is_Stim(i) = ints.(intervention).IS_STIM;
    tableOut.Frequency(i) = ints.(intervention).FREQ;
    tableOut.Intensity(i) = ints.(intervention).INTENSITY;
end

% Move the IS_STIM, FREQ, and INTENSITY columns to the right of the intColName column
tableOut = movevars(tableOut, {'Is_Stim', 'Frequency', 'Intensity'}, 'After', intColName);
tableOut.Is_Stim = categorical(tableOut.Is_Stim);
tableOut.Frequency = categorical(tableOut.Frequency);
tableOut.Intensity = categorical(tableOut.Intensity);