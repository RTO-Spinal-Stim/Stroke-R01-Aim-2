function [isMissing] = checkMissing(fileName, missingFilesPartsToCheck)

%% PURPOSE: CHECK IF A FILE NAME IS MISSING BY WHETHER EACH PART MATCHES
% Inputs:
% fileName: The name of the file (not the absolute path)
% missingFilesPartsToCheck: Cell array of underscore delimited file parts of missing file (not a real file name)
% 
% Outputs:
% isMissing: boolean

% Example:
% missingFilesPartsToCheck{1} = 'SS32_SHAM2_POST_SSV_2'

isMissing = false;
for missingFileNum = 1:length(missingFilesPartsToCheck)    
    missingFile = missingFilesPartsToCheck{missingFileNum};
    missingFileParts = strsplit(missingFile, '_');
    missingIdx = false(length(missingFileParts),1);
    for partNum = 1:length(missingFileParts)
        missingIdx(partNum) = contains(fileName, missingFileParts{partNum});
    end
    if all(missingIdx)
        isMissing = true;
        return;
    end
end