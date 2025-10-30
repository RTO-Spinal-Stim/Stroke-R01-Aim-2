# Initialization
1. Define subject folder to load from and .mat file path to save to
2. Load the configuration from config.json file
3. Load all of the data and place into struct
4. Organize EMG data into separate muscles
5. Extract .num field of GaitRite and XSENS data
6. Fix muscle mappings of EMG sensors

# Preprocess EMG
Filter EMG for each muscle in each trial:
1. Subtract mean
2. Bandpass filter (4Hz, 100Hz)
3. Rectify (abs value)
4. Lowpass filter (5Hz)

# Process GaitRite
1. Split each spreadsheet into its individual trials
2. For each trial, calculate spatiotemporal metrics:
    - Step length symmetry `stepLenSym`
    - Swing time symmetry `swingTimeSym`
    - Left and right swing and stance start and end times (in seconds) `leftStanceSeconds`
    - Convert times from seconds to GaitRite frame indices (120 Hz) `leftStanceIndices`
    - Left and right swing and stance durations (in frames) `leftStanceDurations`
    - Mean L/R swing/stance durations (in frames) `leftStanceDuration`
    - Mean L/R total duration (in frames) `totalLeft`
    - Mean L/R proportion of swing/stance (in frames) `leftStanceProportion`
    - Mean duration (percentage) of L/R swing `leftSwingIdx`
    - Average the step length symmetry values `avgStepLenSym`
    - Average the swing time symmetry values `avgSwingTimeSym`
3. Convert start and end indices to EMG sample rate (2000 Hz) `leftStanceEMG`
4. Convert start and end indices to XSENS sample rate (100 Hz) `leftStanceXSENS`

# Intermediate Processing
1. Put loaded data into “organizedData” struct
2. Rename struct fields for GaitRite, EMG, and XSENS to remove naming redundancies

# Downsample & append EMG and XSENS to 101 frames
1. Get the number of gait cycles in each trial (N) (N ~ 3)
2. Extract the data within each gait cycle
3. Vertically append each gait cycle's data, yielding a N x 101 matrix for each trial
4. Vertically append each trial's N x 101 matrix for each of pre & post SSV & FV, for left and right separately (for 3 trials, will be a 3N x 101 matrix)
5. EMG only: Obtain the MVC as the maximum observed value for each muscle. Divide the muscle's EMG data by that value to normalize the matrix to 0-1.
6. Take the average of this matrix along the first dimension, resulting in a 1x101 matrix.

# Data Analysis
1. Calculate muscle synergies
2. Statistical Parametric Mapping (SPM)
3. Difference in RL calculation (amplitude and duration)
    - EMG
    - XSENS

# Store Outcome Measures Per Intervention, Pre & Post

