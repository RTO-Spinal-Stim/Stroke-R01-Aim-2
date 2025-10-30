%% MT 01/14/25: I think this file can be deleted, but need to ask Ameen.

function mainRun
    clear;
    clc;

    % Select Subject Folder
    disp('Select the PRE data folders:');
    subjectFolderPath = uigetdir('', 'Select the Subject data folder');
    if subjectFolderPath == 0
        disp('No folder selected for PRE data. Exiting.');
        return;
    end

    processData('Pre', subjectFolderPath);

    processData('Post', subjectFolderPath);
end

function processData(dataType, subjectFolderPath)
    % Manually select the EMG data folder
    emgFolderPath = uigetdir('', ['Select the EMG data folder for ' dataType]);
    if emgFolderPath == 0
        disp('No folder selected for EMG data. Exiting.');
        return;
    end
    allEMGData = loadMatFiles(emgFolderPath);

    % Manually select the GAITRITE data folder
    gaitFolderPath = uigetdir('', ['Select the GAITRITE data folder for ' dataType]);
    if gaitFolderPath == 0
        disp('No folder selected for GAITRITE data. Exiting.');
        return;
    end
    allGAITData = loadExcelFilesWithPre(gaitFolderPath);

    % Manually select the XSENS data folder
    xsensFolderPath = uigetdir('', ['Select the XSENS data folder for ' dataType]);
    if xsensFolderPath == 0
        disp('No folder selected for XSENS data. Exiting.');
        return;
    end
    allXSENS = loadXsens(xsensFolderPath);

    %% Pre-Process DATA
    EMG_Fs = 1926; %Delsys sampling freq
    GAIT_Fs = 120;
    X_Fs = 100;

    %Pre-Process EMG Data
    filteredEMG = preprocessEMG(allEMGData, EMG_Fs);

    %Process GAITRite Data
    processedGait = processGAITRite(allGAITData, GAIT_Fs, EMG_Fs, X_Fs);

    %Average EMG for all gait cycles and trials
    [averagedEMG, accumulatedEMG] = downSampleAveragedEMG(filteredEMG, processedGait);

    %Average XSens for all gait cycles and trials
    [accumulatedJointAngles, averagedXSENS]  = downSampleAveragedXSENS(allXSENS, processedGait);

    %% Analysis

    %Calculate Muscle Synergies
    [synergiesNeeded, VAF_values] = calculateSynergies(averagedEMG);

    %SPM Analysis for both XSens and EMG
    X_SPM = SPM_Analysis(accumulatedJointAngles);
    EMG_SPM = SPM_Analysis(accumulatedEMG);

    %Calculate the differences between right and left side for both XSENS and EMG
    X_RLdifference = differenceInRLCalc(X_SPM, averagedXSENS);
    EMG_RLdifference = differenceInRLCalc(EMG_SPM, averagedEMG);

%% Save Data
    % After all processing and analysis:
    subjectMetrics.synergy = [synergiesNeeded; VAF_values];
    subjectMetrics.XSENS = X_RLdifference;
    subjectMetrics.EMG = EMG_RLdifference;

    % Save the subjectMetrics struct in the designated folder
    saveFolderPath = fullfile(subjectFolderPath, '..', dataType); % Adjust the path as needed
    saveFileName = fullfile(saveFolderPath, [dataType '_subjectMetrics.mat']);
    save(saveFileName, 'subjectMetrics');

    % Rename variables to include dataType prefix
    vars = who;
    for i = 1:length(vars)
        eval([dataType '_' vars{i} ' = ' vars{i} ';']);
    end
end