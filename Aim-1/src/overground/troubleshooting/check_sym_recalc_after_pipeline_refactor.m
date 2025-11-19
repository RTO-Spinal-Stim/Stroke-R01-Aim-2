p_new = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected_0_1_reproduced\matchedCycles.csv";
p_orig = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected_0_1_Orig\matchedCycles.csv";

Tnew = readtable(p_new);
Torig = readtable(p_orig);

stepL_new = Tnew.StepLengths_GR_Sym;
stepL_orig = Torig.StepLengths_GR_Sym;

figure;
scatter(1:height(stepL_new), stepL_new);
figure;
scatter(1:height(stepL_orig), stepL_orig);