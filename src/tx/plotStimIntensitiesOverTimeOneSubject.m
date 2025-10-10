function [] = plotStimIntensitiesOverTimeOneSubject(reportTable, subject, overlap)

%% PURPOSE: PLOT THE STIMULATION INTENSITIES FOR EACH MINUTE FOR EACH TX SESSION
% Inputs:
% reportTable: The table containing all stim intensities for all subjects
% subject: The subject of interest to plot
% overlap: boolean to indicate whether each tx's line should overlap
%
% Outputs:
% fig: The generated figure

if ~exist('overlap','var')
    overlap = true;
end

fig = figure('Name', subject);
ax = axes(fig);
hold(ax, 'on');

subjectRowsIdx = ismember(reportTable.Subject, subject);
subjectTable = reportTable(subjectRowsIdx,:);
numRowsOneSubject = height(subjectTable);
p = gobjects(numRowsOneSubject,1);
sessionLabels = cell(size(p));
cmap = turbo(numRowsOneSubject);
txTicks = NaN(numRowsOneSubject,1);
for i = 1:numRowsOneSubject
    stimIntensities = subjectTable.StimIntensities{i};
    % stimIntensities(stimIntensities==0) = NaN; % Remove the large lines to zero
    xOverlap = 0:length(stimIntensities)-1;
    x = xOverlap;
    if ~overlap
        x = x + 45*(i-1);
    end
    txTicks(i) = mean(x);
    if mod(i,2) == 1
        color = 'k';
    else
        color = 'b';
    end
    p(i) = plot(ax, x, stimIntensities, 'Color', color);
    sessionLabels{i} = ['TX' num2str(i)];
    p(i).DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Session', repmat(sessionLabels(i), size(x)));    
end
xlim([0 max(x) + 45]);
xticks(txTicks);
xticklabels(sessionLabels);

xlabel('TX sessions');
ylabel('Stimulation Intensity (mA)');

title([subject ' TX Stimulation Intensities']);
 
% legend(p, sessionLabels, 'AutoUpdate', 'off');
