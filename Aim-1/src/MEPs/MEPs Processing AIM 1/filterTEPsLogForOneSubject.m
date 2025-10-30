function [tepsLogOneSubject] = filterTEPsLogForOneSubject(tepsLog, subjectNameHeader, subject)

%% PURPOSE: FILTER THE TEPS LOG FOR ONE SUBJECT.
% subject = 'SS13';

if isnumeric(subject)
    subject = num2str(subject);
end

tepsLogOneSubject = table;
for i = 1:height(tepsLog)
    currSubject = strtrim(tepsLog.(subjectNameHeader)(i));
    currSubject = currSubject{1};
    if isequal(currSubject, subject)
        tepsLogOneSubject = [tepsLogOneSubject; tepsLog(i,:)];
    end
end