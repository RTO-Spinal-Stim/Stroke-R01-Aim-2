basePath = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data';
config = jsondecode(fileread('Y:\LabMembers\MTillman\GitRepos\Stroke-R01\Troubleshooting\MissingFiles\missingFilesConfig.json'));

subjects = config.SUBJECT_LIST;
interventions = config.INTERVENTION_LIST;

for subNum = 1:length(subjects)
    subject = subjects{subNum};
    subjectTEPsFolder = fullfile(basePath, subject, 'TEPs');
    for intNum = 1:length(interventions)
        intervention = interventions{intNum};
        subjectIntTEPsFolder = fullfile(subjectTEPsFolder, intervention);
        prevTEPsFileNamePre = [subject '_' intervention '_PRE'];
        prevTEPsFileNamePost = [subject '_' intervention '_POST'];
        prevTEPsFilePathPre = fullfile(subjectIntTEPsFolder, prevTEPsFileNamePre);
        prevTEPsFilePathPost = fullfile(subjectIntTEPsFolder, prevTEPsFileNamePost);
        newTEPsFileNamePre = [subject '_TEPS_' intervention '_PRE'];
        newTEPsFileNamePost = [subject '_TEPS_' intervention '_POST'];
        newTEPsFilePathPre = fullfile(subjectIntTEPsFolder, newTEPsFileNamePre);
        newTEPsFilePathPost = fullfile(subjectIntTEPsFolder, newTEPsFileNamePost);
        % Rename the files.
        if isfile([prevTEPsFilePathPre '.mat'])
            movefile([prevTEPsFilePathPre '.mat'], [newTEPsFilePathPre '.mat']);
        end
        if isfile([prevTEPsFilePathPre '.adicht'])
            movefile([prevTEPsFilePathPre '.adicht'], [newTEPsFilePathPre '.adicht']);
        end
        if isfile([prevTEPsFilePathPost '.mat'])
            movefile([prevTEPsFilePathPost '.mat'], [newTEPsFileNamePost '.mat']);
        end
        if isfile([prevTEPsFilePathPost '.adicht'])
            movefile([prevTEPsFilePathPost '.adicht'], [newTEPsFileNamePost '.adicht']);
        end
    end
end