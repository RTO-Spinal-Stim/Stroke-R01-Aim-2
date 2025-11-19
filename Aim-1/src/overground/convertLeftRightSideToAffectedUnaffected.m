function [tableOut] = convertLeftRightSideToAffectedUnaffected(tableIn, demsTable, tableInColToConvert, demsTableColName)

%% PURPOSE: CONVERT 'L' AND 'R' TO 'U' AND 'A' FOR UNAFFECTED AND AFFECTED SIDE
% Inputs:
% tableIn: The table of data to convert the side for.
% demsTable: The table containing the un/affected side information. Each
% row is one participant.
% tableInColToConvert: The column name in tableIn to convert
% demsTableColName: The column name in the demographic table that lists
% the affected side
%
% Outputs:
% tableOut: The table with the converted side

disp('Converting L(eft) & R(ight) to U(naffected) & A(ffected)')

tableOut = tableIn;

varNames = demsTable.Properties.VariableNames;
for i = 1:width(demsTable)
    demsTable.(varNames{i}) = categorical(demsTable.(varNames{i}));
end

for i = 1:height(demsTable)
    currSubject = demsTable.Subject(i);
    affectedSide = demsTable.(demsTableColName)(i);

    currSubjectIdx = ismember(tableIn.Subject, currSubject);

    currSubjectAffectedSideIdx = ismember(tableIn.(tableInColToConvert), affectedSide) & currSubjectIdx;
    currSubjectUnaffectedSideIdx = ~ismember(tableIn.(tableInColToConvert), affectedSide) & currSubjectIdx;

    tableOut.(tableInColToConvert)(currSubjectAffectedSideIdx) = 'A';
    tableOut.(tableInColToConvert)(currSubjectUnaffectedSideIdx) = 'U';

end

tableOut.(tableInColToConvert) = categorical(tableOut.(tableInColToConvert));