# Import the file paths.
source(file.path("src", "stats", "paths_tasks_gait_phase.R"))

# Import packages
library("importpackages")

pkg_name = "BetweenConditionsGroup_GaitPhase_TurnStrategy"
package_names <- c("lme4", "emmeans", "lmerTest", "languageR",
                   "effects", "ggeffects", "dplyr", "tidyverse", "knitr", "kableExtra", "gridExtra", "CommonUtils", "ggpubr","configr")
loaded_packages <- import_packages_by_name(package_names)

trial_name_col_name = "Trial"
subject_name_col_name = "Subject"
task_name_col_name = "Task"
gait_phase_col_name = "Gait_Phase"
turnstrategy_col_name = "Turn_Strategy"
grouping_factors = c(gait_phase_col_name, turnstrategy_col_name)
factors_col_names = c(subject_name_col_name, gait_phase_col_name, turnstrategy_col_name) # Factors to include in the model
factors_col_names_reps = c(subject_name_col_name, trial_name_col_name, gait_phase_col_name, turnstrategy_col_name, "Repetition") # All iteration columns

pkg_output_folder = file.path(output_folder_path, pkg_name)
if (!dir.exists(pkg_output_folder)) {
  dir.create(pkg_output_folder)
}

#############################
## READ IN DATA
#############################
all_data <- read_data(data_file_path, factors_col_names) # From fcns.R
all_data$Repetition <- as.factor(all_data$Repetition)

# Reorder the levels of the Task factor
all_data$Task <- factor(all_data$Task, levels = c("Straight_Line_Gait", "TWW_Preplanned"))
# Put the gender column after the Repetition column
all_data <- all_data %>% relocate(Gender, .after = Repetition)
all_data$Gender <- as.factor(all_data$Gender)
# Put the turn strategy column after the Gender column
all_data <- all_data %>% relocate(Turn_Strategy, .after = Gender)
all_data$Turn_Strategy <- as.factor(all_data$Turn_Strategy)
all_data <- remove_levels(all_data, "Task", "Straight_Line_Gait")

# Get the column names of interest from the data table
first_var_col_num <- 8 # Skips Gender
col_names <- get_col_names(first_var_col_num, all_data) # From fcns.R
col_name = col_names[1]

lmer_formula <- "~ Gait_Phase*Turn_Strategy + (1|Subject)"
emmeans_formula <- "~ Gait_Phase*Turn_Strategy"

emmeans_list <- list()
comps_list <- list()

colors_toml_path <- "/Users/mitchelltillman/Desktop/Work/Stevens_PhD/Dissertation/plot_colors.toml"
colors <- read.config(file = colors_toml_path, file.type = "toml")
fill_factor <- "Turn_Strategy"

# Run the hypothesis testing and plotting functions
for (col_name in col_names) {

  if (!is.numeric(all_data[[col_name]])) {
    print(paste("The column", col_name, " is not numeric."))
    next
  }

  # Open the PDF device
  pdf(file = file.path(pkg_output_folder, paste0(col_name, ".pdf")))

  # Create a data frame for the current column
  curr_data <- curr_col_data(all_data, col_name, factors_col_names_reps)

  # Create the lmer model
  lmer_model <- make_model(curr_data, lmer_formula, col_name)

  # Get the marginal means
  emmeans <- get_emmeans(lmer_model, emmeans_formula, col_name)
  emmeans_list[[col_name]] <- emmeans

  # Hypothesis tests
  comps <- hyp_tests(lmer_model, curr_data, emmeans, col_name)
  comps_list[[col_name]] <- comps

  # Bar graph with difference bars
  bar_graph_with_diff_bars(curr_data, comps, grouping_factors, col_name, emmeans, colors=colors, fill_factor=fill_factor, min_y_distance=0.05, text_size=2)

  # Line plots
  line_plot_from_lmer(curr_data, col_name, lmer_model)

  # Bar graphs
  bar_plot_from_lmer(curr_data, col_name, lmer_model, comps)

  # Interaction plots
  interaction_plot_from_lmer(curr_data, col_name, lmer_model, comps, x_axis_factor = "Gait_Phase", color_factor = "Turn_Strategy", facet_factors = NULL)

  # Summarize and plot the residuals of the model
  summarize_model(lmer_model)

  # Create the histogram
  plot_all_histograms(curr_data, c(gait_phase_col_name), col_name, fill_factor = "Turn_Strategy") # Per task

  dev.off()
}

toml_file_path <- "config_transverse_gaitphases.toml"
latex_table_path <- file.path(pkg_output_folder, "latex_table.tex")

# Named list to map long factor names to shorter names
name_mapping <- list(
  "Gait_Phase" = list(
    "LeftDoubleSupport" = "LDS",
    "RightDoubleSupport" = "RDS",
    "LeftSingleSupport" = "LSS",
    "RightSingleSupport" = "RSS"
  ),
  "Task" = list(
    "Straight_Line_Gait" = "SLG",
    "TWW_Preplanned" = "PP",
    "TWW_Latecued" = "LC"
  )
)

config <- read.config(file = toml_file_path, file.type = "toml")
vars_list <- config$vars

# Generate the latex table
latex_output <- generate_latex_table(comps_list, emmeans_list, name_mapping, vars_list, n_decimals=3)
string_vector <- unlist(latex_output)
writeLines(string_vector, latex_table_path)
