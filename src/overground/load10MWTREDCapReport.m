function [reportTableOrdered] = load10MWTREDCapReport(reportPath)

%% PURPOSE: LOAD THE 10MWT REPORT FROM REDCAP
% Inputs:
% reportPath: The path to the csv file of the report
%
% Outputs:
% reportTableOrdered: The table with the report's data, ordered by subject
% and session

reportTable = table;

rawReport = readtable(reportPath);

assessmentSessionMappings = {
    1,'BL';
    2,'MID18';
    3,'MID24';
    4,'POST18';
    5,'POST24';
    6,'MO1FU';
    7,'MO3FU'
};

trainingSessionMappings = {
    2.04,'4';
    2.07,'7';
    2.1,'10';
    2.13,'13';
    2.16,'16';
    2.19,'19';
    2.22,'22';
};

for i = 1:height(rawReport)
    row = rawReport(i,:);
    tmpTable = table;
    tmpTable.Subject = row.record_id;
    mapping = NaN;
    if ~isnan(row.visit)
        sessionRaw = row.visit;
        mapping = assessmentSessionMappings;
    elseif ~isnan(row.timepoint)
        sessionRaw = row.timepoint;
        mapping = trainingSessionMappings;
    end
    sessionIdx = ismember(cell2mat(mapping(:,1)), sessionRaw);
    session = mapping{sessionIdx, 2};
    tmpTable.Session = {session};
    tmpTable.AverageSSVTime_Seconds = row.ssv_avgtime;
    tmpTable.AverageSSVSpeed_MPS = row.ssv;
    tmpTable.AverageFVTime_Seconds = row.fv_avgtime;
    tmpTable.AverageFVSpeed_MPS = row.fv;
    reportTable = [reportTable; tmpTable];
end

%% Sort the rows of each subject
sortOrder = {'BL','4','7','MID18','10','MID24','13','16','POST18','19','22','POST24'};
subjects = unique(reportTable.Subject,'stable');
reportTableOrdered = table;
for i = 1:length(subjects)
    subject = subjects{i};
    subjectRowsIdx = ismember(reportTable.Subject, subject);
    subjectTable = reportTable(subjectRowsIdx,:);
    for j = 1:length(sortOrder)
        rowIdx = ismember(subjectTable.Session, sortOrder(j));
        if ~any(rowIdx)
            continue;
        end
        reportTableOrdered = [reportTableOrdered; subjectTable(rowIdx,:)];
    end
end
