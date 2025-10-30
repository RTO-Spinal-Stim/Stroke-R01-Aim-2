p = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCycles.csv";

% p = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\unmatchedCycles.csv";
T = readtable(p);
varNames = T.Properties.VariableNames;
% varNamesSymIdx = contains(varNames, {'_GR', '_EMG', 'JointAngles'});
varNamesSymIdx = contains(varNames, {'_GR', '_EMG', 'JointAngles'}) & ~contains(varNames, {'AUC','Min','Max'}) & contains(varNames, {'_Sym'});
varNamesSym = varNames(varNamesSymIdx);

for i = 1:length(varNamesSym)
    varName = varNamesSym{i};
    minV = min(T.(varName),[],1,'omitnan');
    maxV = max(T.(varName),[],1,'omitnan');
    disp(['Variable: ' varName ' Min: ' num2str(minV) ' Max: ' num2str(maxV)]);
    % if minV < 0 || maxV < 0
    %     disp(['FOUND NEGATIVE VALUE IN ' varName]);
    % end
    if minV < 0 || maxV > 1
        disp(['FOUND VALUE OUTSIDE RANGE IN ' varName]);
    end
end