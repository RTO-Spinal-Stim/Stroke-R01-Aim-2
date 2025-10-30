## 4/17/25 MT
## THIS FILE WAS INTENDED TO CHECK WITHIN EACH SUBJECT WHETHER ANY GROUP IS DIFFERENT FROM ANY OTHER GROUP.
## HOWEVER, A LINEAR MIXED MODEL IS NOT APPROPRIATE BECAUSE WITHIN-SUBJECT THERE IS NO RANDOM EFFECT.
import tomli
import tomli_w
import pandas as pd
import subprocess

# 1. Read the Rconfig file.
config_path = "Y:\LabMembers\MTillman\GitRepos\Stroke-R01\src\RCode\Rconfig.toml"
with open(config_path, 'rb') as f:
    config = tomli.load(f)

# 2. Modify the formulae
lmer_formula = "~ Intervention"
emmeans_formula = "~ Intervention"
config["stats"]["lmer_formula"] = lmer_formula
config["stats"]["emmeans_formula"] = emmeans_formula
config['all_factor_columns'].remove("Subject")
config['all_factor_columns'].remove("Side")
config['all_factor_columns'].remove("Cycle")
config['all_factor_columns'].append("PrePost")
config['all_factor_columns'].append("GaitCycle")

# 3. Save the updated config file
new_config_path = config_path.replace("Rconfig", "Rconfig_onesubject")
with open(new_config_path, 'wb') as f:
    tomli_w.dump(config, f)

# 4. Load the data file.
data_file_path = "Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\MergedTablesAffectedUnaffected\matchedCyclesCGAM.csv"
df = pd.read_csv(data_file_path)

# 5. Filter for each subject
# Get unique subjects
subjects = df["Subject"].unique()
subjects.sort()
# Filter the df and run the R code.
for subject in subjects:
    # Write the one subject's data file to disk
    filtered_df = df[df["Subject"] == subject]
    filtered_df.drop("Subject", axis = 1, inplace=True)
    subject_df_file_path = f"Y:\LabMembers\MTillman\SavedOutcomes\StrokeSpinalStim\Overground_EMG_Kinematics\PerSubject_Tmp\{subject}.csv"
    filtered_df.to_csv(subject_df_file_path, index=False)
    with open(new_config_path, 'rb') as f:
        new_config = tomli.load(f)

    new_config_path_curr = new_config_path.replace('onesubject', 'currsubject')
    # new_config['paths']['root_save'] = os.path.join(new_config['paths']['root_save'], subject)
    new_config['paths']['data_file'] = subject_df_file_path
    new_config['analysis_name'] = "Changers_" + subject
    with open(new_config_path_curr, 'wb') as f:
        tomli_w.dump(new_config, f)

    # Execute the R code for this subject
    command = [
        "C:\\Users\\mtillman\\AppData\\Local\\Programs\\R\\R-4.4.2\\bin\\Rscript.exe",
        "Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\src\\RCode\\main.R"
    ]
    result = subprocess.run(command, check=True, capture_output=True, text=True)