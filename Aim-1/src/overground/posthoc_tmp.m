%% Calculate CGAM from synergies
matchedCyclesPath = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCycles.csv";
matchedCycleTable = readtable(matchedCyclesPath);
categoricalCols = {'Subject','Intervention','SessionOrder','Is_Stim','Frequency','Intensity','PrePost','Speed','Trial','Cycle','Side'};
matchedCycleTable.Frequency(ismissing(matchedCycleTable.Frequency)) = 0;
for i = 1:length(categoricalCols)
    matchedCycleTable.(categoricalCols{i}) = categorical(matchedCycleTable.(categoricalCols{i}));
end
vif_cutoff = config.VIF_CUTOFF;
% Right off the bat, drop specific columns because bad data.
columnsToDrop = {'StanceDurations_GR_Sym','StrideWidths_GR_Sym','Single_Support_Time_GR_Sym','Double_Support_Time_GR_Sym'};
droppedColsTable = removevars(matchedCycleTable, columnsToDrop);
% Remove the variables that are negative or not symmetries.
varNames = droppedColsTable.Properties.VariableNames;
varsToKeepIdx = contains(varNames, '_Sym') & ~ismember(varNames, 'NumSynergies_Sym') & ~contains(varNames, {'AUC','RMS_EMG','JointAngles_Max','JointAngles_Min'});
symmetryTable = removevars(droppedColsTable, varNames(~varsToKeepIdx));

independentVars = independentVarsFromVIF(symmetryTable, vif_cutoff);
varsToKeepIdxCat = varsToKeepIdx | ismember(varNames, categoricalCols);
symmetryTableWithName = removevars(droppedColsTable, varNames(~varsToKeepIdxCat));
nonGRvarNames = ~contains(symmetryTableWithName.Properties.VariableNames, '_GR') & ~ismember(symmetryTableWithName.Properties.VariableNames, categoricalCols);
grSymTableWithName = removevars(symmetryTableWithName, nonGRvarNames);
grVarNames = symmetryTableWithName.Properties.VariableNames(contains(symmetryTableWithName.Properties.VariableNames, '_GR'));

[cgamTable, matrixStats] = calculateCGAM(symmetryTableWithName, independentVars);
f = 'Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\investigating_cgam';
cgamLevel = 'subject_intervention_prepost_speed';
cgamPath = fullfile(f, [cgamLevel '_CGAM.csv']);
statsPath = fullfile(f, [cgamLevel '_Stats.csv']);
writetable(cgamTable, cgamPath);
writetable(matrixStats, statsPath);
matchedCycleTable = addToTable(matchedCycleTable, cgamTable);

%% cohen's d
catVars = {'Subject', 'Intervention', 'Speed'};
catVarsPrePost = {'Subject', 'Intervention', 'Speed', 'PrePost'};
p = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\investigating_cgam\subject_CGAM.csv";
T = readtable(p);
uniqueRows = unique(T(:, catVars), 'rows','stable');
cohensds = NaN(height(uniqueRows),1);
cohensdTable = uniqueRows;
for i = 1:height(uniqueRows)
    row = uniqueRows(i,:);
    preRow = row;
    preRow.PrePost = categorical({'PRE'});
    postRow = row;
    postRow.PrePost = categorical({'POST'});
    preDataIdx = ismember(T(:, catVarsPrePost), preRow, 'rows');
    postDataIdx = ismember(T(:, catVarsPrePost), postRow, 'rows');
    preData = T(preDataIdx,'CGAM');
    postData = T(postDataIdx,'CGAM');
    cohensd = meanEffectSize(preData.CGAM, postData.CGAM, 'Effect','cohen');
    cohensds(i) = cohensd.Effect;
    cohensdTable.cohensd(i) = cohensd.Effect;
    disp([row.Subject{1} ' ' row.Intervention{1} ' ' row.Speed{1} ' Cohens D: ' num2str(cohensds(i))]);
end
scatter(1:length(cohensds), cohensds);
ylabel('Cohens d of CGAM');

%% Best day
catVars = {'Subject'};
uniqueSubj = unique(cohensdTable(:, catVars),'rows','stable');
bestCohens = NaN(height(uniqueSubj),1);
for i = 1:height(uniqueSubj)
    subjIdx = tableContains(cohensdTable, uniqueSubj(i,:));
    bestCohens(i) = max(cohensdTable(subjIdx,'cohensd'));
end
scatter(1:length(bestCohens), bestCohens);