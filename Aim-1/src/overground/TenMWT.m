trialTablePath = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\trialTableAll.csv";
trialTable = readtable(trialTablePath);

tepsPath = "Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\TEPs_log.xlsx";
tepsLog = readExcelFileOneSheet(tepsPath, 'Subject', 'Sheet1');

colName = 'FV_AVG_m_s';

newTable = table;
newTable.Subject = tepsLog.Subject;
newTable.SessionOrder = tepsLog.SessionOrder; 
newTable.SessionCode = tepsLog.SessionCode;
newTable.Pre_Post = tepsLog.Pre_Post;
newTable.MWT = tepsLog.(colName);

preIdx = ismember(newTable.Pre_Post, 'PRE');
preTableAll = newTable(preIdx,:);

preTable = table;
preTable.Subject = categorical(preTableAll.Subject);
% preTable.Intervention = categorical(preTableAll.SessionCode);
preTable.InterventionOrder = categorical(preTableAll.SessionOrder);
preTable.MWT = preTableAll.MWT;

% wideTable = pivot(preTable, 'Subject', 'Intervention', 'MWT');
wide_table = unstack(preTable, 'MWT', 'InterventionOrder');
for i = 1:6
    tmpNum = ['x' num2str(i)];
    sessionNum = ['Session' num2str(i)];
    wide_table = renamevars(wide_table, tmpNum, sessionNum);
end

% Fit the ANOVA
wide_table = removevars(wide_table, 'Subject');
withinDesign = table((1:6)', 'VariableNames', {'Session'});
rm = fitrm(wide_table, 'Session1-Session6~1', 'WithinDesign',withinDesign);

% Perform the ANOVA
rmANOVA = ranova(rm);
disp(rmANOVA);

result = multcompare(rm, 'Session');

ranovatbl = ranova(rm);

% Swarmchart plot
fig = figure;
hold on;
for i = 1:width(wide_table)
    xs = repmat(i, height(wide_table), 1);
    swarmchart(xs, wide_table.(['Session' num2str(i)]), 'filled');
end
xticks(1:6);
title('Average PRE FV 10MWT');
ylabel('Speed (m/s)');

% Scatter plot
fig = figure;
hold on;
x = [];
y = [];
turbo_full = turbo(256);
indices = round(linspace(1, 256, height(wide_table)));
custom_turbo_colormap = turbo_full(indices, :);
subjColors = [];
for i = 1:width(wide_table)
    x = [x; repmat(i, height(wide_table), 1)];
    y = [y; table2array(wide_table(:, i))];
    subjColors = [subjColors; custom_turbo_colormap];
end

scatter(x, y,60,subjColors,'filled');

% Add diff lines
for colNum = 1:width(wide_table)-1
    for subNum = 1:height(wide_table)
        y1 = wide_table.(['Session' num2str(colNum)])(subNum);
        y2 = wide_table.(['Session' num2str(colNum+1)])(subNum);
        line([colNum, colNum+1], [y1, y2], 'Color', subjColors(subNum,:));
    end
end
xticks(1:6);
title('Average PRE FV 10MWT');
ylabel('Speed (m/s)');

% Add dashed first to last lines
% for subNum = 1:height(wide_table)
%     y1 = wide_table.(['Session' num2str(1)])(subNum);
%     y2 = wide_table.(['Session' num2str(6)])(subNum);
%     line([1, 6], [y1, y2], 'Color', subjColors(subNum,:),'LineStyle','--');
% end

% Add mean point
for colNum = 1:width(wide_table)
    meanVal = mean(wide_table.(['Session' num2str(colNum)]));
    scatter(colNum, meanVal,500,'k','x','LineWidth',3);
end