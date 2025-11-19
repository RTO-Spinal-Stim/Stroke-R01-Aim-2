run_all <- function(paths_file_path,
                    analysis_name,
                    all_data,
                    col_names,
                    factors_col_names,
                    grouping_factors,
                    histogram_fill_factor = "Subject",
                    repetition_col_name = "Repetition",
                    interaction_facet_factors = NULL) {
  # Load the paths file
  source(paths_file_path)

  library("importpackages")

  package_names <- c("lme4", "emmeans", "lmerTest", "languageR",
                     "effects", "ggeffects", "dplyr", "tidyverse", "knitr", "kableExtra", "gridExtra", "CommonUtils", "ggpubr", "configr")
  loaded_packages <- import_packages_by_name(package_names)


}
