The steps are still correct, but the data format is not because I use tables now.
# 1. Initialization
1. Define subject folder to load from and the .mat file path to save to
2. Load the configuration from config.json file

# 2. Load XSENS, GaitRite, and Delsys data.
Input: Folder path
Output: hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).loaded
    - "hardwareStruct" is any of "XSENSStruct", "DelsysStruct", "GaitRiteStruct"

# 3. Filter Delsys
Input: DelsysStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).loaded
Output: DelsysStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).filtered

# 4. Filter XSENS
Input: XSENSStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).loaded
Output: XSENSStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).filtered

# 5. Calculate GaitRite spatiotemporal measures
Input: GaitRiteStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).loaded
Output: GaitRiteStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).spatiotemporal

# 6. Time sync the XSENS and Delsys signals to GaitRite
Inputs: 
    - GaitRiteStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).spatiotemporal
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).filtered
Outputs: 
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).timeSync

# 7. Split the XSENS & Delsys data by gait cycle
Inputs: 
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).timeSync
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).filtered
Outputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).GaitCycles.(cycle#).filtered

# 8. Downsample/time-normalize the XSENS & Delsys data per gait cycle
Inputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).GaitCycles.(cycle#).filtered
Outputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).GaitCycles.(cycle#).timeNormalized

# 9. Aggregate & average each gait cycle of the XSENS & Delsys data
Inputs: 
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Trials.(trial#).GaitCycles.(cycle#).timeNormalized
Outputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Aggregated
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Averaged

# 10. Run SPM L vs. R across each gait cycle within one condition (intervention, pre/post, ssv/fv)
Inputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Aggregated
Outputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).SPM

# 11. Get the average magnitudes and durations of L vs. R differences in each muscle/joint
Inputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).SPM
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).Averaged
Outputs:
    - hardwareStruct.(intervention_name).(ssv/fv).(pre/post).LRDiffs