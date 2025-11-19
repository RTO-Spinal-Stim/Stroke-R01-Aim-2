# main.m
1. Define the paths
2. Load the configuration from JSON.

# A_Smers_processing_dataPrep.m
1. Load in the TEPs log
2. Iterate over each intervention for all following steps
3. Get the .mat files for the pre & post TEPs for this intervention
4. Extract the file's row in the TEPs log.
5. Load the TEPs .mat file.
6. Delete rows that contain "RVL", "LRV", "STIM", and "KNEE" (?)
7. Correct the channel names that were mislabeled using "A_channels.json"
8. Organize the data into a struct where each field is one muscle, arranged as a M x N matrix. M = number of pulses, N = number of data points in each pulse.
9. Check that the number of pulses is divisible by 5, otherwise log it.
10. Run the lowpass filter on the raw data.
11. Run the bandpass filter on the raw data.
12. Shift the bandpass filtered data, aligning to the "last reference"
13. Rectify the bandpassed & aligned signal
14. Get the index of stim onset using `getStimOnsetMax`.
15. Smooth the bandpassed data (using a moving window?)
16. Shift the smoothed data (?)
17. Rectify the signal again?...
18. Save a struct with all interventions' output.

# B_Smers_P2P_AUC.m
1. Load the interventions' struct.
2. Initialize or load a processing log.
3. Load the saved part B .mat file, if it exists.
4. Create a figure for manual evaluation of TEPs
5. Based on manual input, auto-detect the peaks?
6. Calculate the AUC from the rectified signal.
7. Fill in the log with the current process.

# C_Smers_RecruitmentCurves.m
1. Load the .mat file from part B
2. Normalize the value to the max Y?
3. Plot the recruitment curve? 