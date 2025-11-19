read_all_data <- function(common_config, data_file_paths, included_fixed_effects_levels, random_effects, factors_not_in_model) {
  # browser()
  factors_col_names_reps <- c(names(random_effects), names(common_config$fixed_effects), factors_not_in_model)
  # i<-1 # Testing
  all_data <- lapply(1:length(data_file_paths), function(i) {
    data_file_path <- data_file_paths[i]
    print(paste("i", i, "data_file_path", data_file_path))
    factors_col_names <- factors_col_names_reps
    data <- read_data(data_file_path, factors_col_names_reps)
    # If there are any factors in the included_fixed_effects_levels that are not in the data, then add them to the data.

    # For each factor, remove unused levels, and reorder and rename the levels.
    for (factor in names(included_fixed_effects_levels)) {
      if (!factor %in% colnames(data)) {
        # If the factor is not present in this dataset, add it to the dataset.
        levels_of_missing_factor <- included_fixed_effects_levels[[factor]]
        data[[factor]] <- as.factor(levels_of_missing_factor[i])
        # Move this factor to the first column
        data <- data[, c(factor, setdiff(colnames(data), factor))]
        # Reorder the levels of this factor
        data[[factor]] <- factor(data[[factor]], levels = levels_of_missing_factor)
      } else {
        # Clean the factor
        all_factor_levels <- common_config$fixed_effects[[factor]]
        included_factor_levels <- included_fixed_effects_levels[[factor]]
        data <- clean_factor(data, factor, common_config$fixed_effects[[factor]], included_fixed_effects_levels[[factor]])
      }
    }
    # Ensure that all of the random_effects columns are factors too
    for (factor in names(random_effects)) {
      data[[random_effects[[factor]]]] <- factor(data[[factor]])
      # Remove the factor's original name, if different
      if (random_effects[[factor]] != factor) {
        data <- data[, -which(names(data) == factor)]
      }
      # Put the random effect in the front of the data frame
      data <- data[, c(random_effects[[factor]], setdiff(colnames(data), random_effects[[factor]]) )]
    }
    return(data)
  })
  # Combine the list elements into a single data frame
  all_data <- do.call(rbind, all_data)
  return(all_data)
}

clean_factor <- function(data, factor, all_factor_levels, included_factor_levels) {
  # Keep only the rows that have the included levels
  data <- data[data[[factor]] %in% included_factor_levels, ]
  # Remove unused levels of this factor
  data[[factor]] <- as.factor(data[[factor]])
  data <- remove_levels(data, factor, setdiff(names(all_factor_levels), included_factor_levels))
  # Move this factor to the first column
  data <- data[, c(factor, setdiff(colnames(data), factor))]
  # Reorder the levels of this factor
  data[[factor]] <- factor(data[[factor]], levels = included_factor_levels)
  return(data)
}
