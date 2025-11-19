# %% [markdown]
# # Load Config & Initialize Paths

# %%
import tomllib as toml
import os
from pprint import pprint

# Load config
config_path = "Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\src\\stats\\stats_config.toml"
with open(config_path, 'rb') as f:
    config = toml.load(f)
pprint(config)

# Create paths to save files
analysis_name = config["analysis_name"]
analysis_output_folder = os.path.join(config['paths']["root_save"], analysis_name)
if not os.path.exists(analysis_output_folder):
    os.makedirs(analysis_output_folder)
    print(f"Created folder: {analysis_output_folder}")

os.chdir("Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\src\\stats")

# %% [markdown]
# # Load Data

# %%
import pandas as pd

# Load the CSV file into a pandas DataFrame
df = pd.read_csv(config['paths']['data_file'])

pprint(config['all_factor_columns'])

# Make sure the statistical factors are pd.Categorical
for factor in config['all_factor_columns']:
    if factor in config['factors_levels_order']:
        df[factor] = pd.Categorical(df[factor], 
                                        categories=config['factors_levels_order'][factor], 
                                        ordered=True)
    else:
        df[factor] = pd.Categorical(df[factor])

# Get the list of outcome measure column names
outcome_measures_cols = [col for col in df.columns if col not in config['all_factor_columns']]

# Make sure the outcome measures are numeric
for col in outcome_measures_cols:
    df[col] = pd.to_numeric(df[col])

df.head()

# %% [markdown]
# # Process the Data

# %%
# Using pymer4
from pymer4.models import Lmer
lmer_formula_base = config['stats']['lmer']['lmer_formula']
lmer_formula = outcome_measures_cols[0] + lmer_formula_base
outcome_measure = outcome_measures_cols[0]
print(lmer_formula)
print('HIP_RMSE_JointAngles_Diff' in df.columns)
model = Lmer(lmer_formula, data=df)
model.fit()
grouping_vars = ['Intervention', 'Speed']
model.post_hoc(outcome_measure, grouping_vars)

# %%
# Using statsmodels
import sys
import os
current_dir = os.path.dirname(os.path.abspath("__file__"))
sys.path.append(current_dir)
from curr_col_data import curr_col_data
from make_lmer_model import make_lmer_model
vc_formula = None
if "vc_formula" in config['stats']['lmer']:
    vc_formula = config['stats']['lmer']['vc_formula']    
random_effect_factor = config['stats']['lmer']['random_effect_factor']
random_effect_formula_base = config["stats"]["lmer"]["random_effect_formula"]
fixed_effects_formula_base = f"{config['stats']['lmer']['fixed_effects_formula']}"
for col in outcome_measures_cols:

    # Set the random effect formula to have a random slope for the current column
    random_effect_formula = random_effect_formula_base
    if r"{outcome}" in random_effect_formula_base:
        random_effect_formula = random_effect_formula_base.replace(r"{outcome}", col)
    
    # Create a data frame for the current column
    curr_df = curr_col_data(df, col, config['all_factor_columns'])

    # Create the lmer model
    fixed_effects_formula = f"{col} {fixed_effects_formula_base}"
    lmer_model = make_lmer_model(curr_df, fixed_effects_formula, random_effect_factor, random_effect_formula, vc_formula)

    # Get the estimated marginal means

    # Perform the hypothesis testing
    

# %% [markdown]
# ## Save the Results

# %%
# Save the results

# %% [markdown]
# # Plot

# %%
# Plot the results


