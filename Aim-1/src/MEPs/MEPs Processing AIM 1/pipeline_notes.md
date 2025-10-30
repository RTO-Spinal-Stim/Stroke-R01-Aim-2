# main.m
1. Define the paths
2. Load the configuration from JSON.

# Part A: Load & process the TEPs log.
## Load the TEPs log
1. Load the TEPs log from disk (Excel file)
2. Remove any rows at the bottom that are extraneous.
3. Filter the TEPs log for the current subject.

## Process each TEPs file in the log
1. Correct mislabeled channel names.
2. Put the raw data into a struct, where each field is one muscle's MxN data. M = # pulses, N = length of each pulse.
3. Identify & remove the bad pulses
4. Check that the number of pulses is correct.
5. Lowpass & bandpass filter the TEPs data
6. Shift the bandpassed signal to "last reference"
7. Rectify the bandpassed & shifted signal
8. Find where the stimulation artifact is located
9. Use a moving window average to smooth the bandpassed (not shifted) data.
10. Shift the moving averaged data to "last reference".
11. Rectify the moving averaged & shifted data
12. 