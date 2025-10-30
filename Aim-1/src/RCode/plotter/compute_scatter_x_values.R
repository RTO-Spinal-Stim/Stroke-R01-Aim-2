compute_scatter_x_values <- function(df, grouping_factors) {
  # PURPOSE: COMPUTE THE ACTUAL X VALUES FOR EACH POINT IN A SCATTER PLOT
  # INPUTS:
  #   df: data frame (with "group_min/mean/max_x" columns from compute_group_xtick_values)
  #   grouping_factors: factors to group by
  #
  # OUTPUTS:
  #   x: x values for each point
  library(dplyr)
  
  # Get factors in df
  factors <- names(df)[sapply(df, is.factor)]
  
  # Check if all of the grouping factors are factors in the df
  if (!all(grouping_factors %in% factors)) {
    stop("Invalid factor(s). Must be column(s) in data frame")
  }
  
  # Get the unique combinations of the grouping factors. Ignores missing combinations
  unique_combinations <- df %>%
    select(all_of(grouping_factors)) %>%
    distinct()
  
  result_df <- data.frame()
  factor_names <- names(df)[sapply(df, is.factor)]
  for (i in 1:nrow(unique_combinations)) {
    # Filter the data frame for the current unique combination
    current_combination <- unique_combinations[i, ]
    current_df <- df
    for (j in seq_along(grouping_factors)) {
      current_df <- current_df %>%
        filter(.data[[grouping_factors[j]]] == current_combination[[grouping_factors[j]]])
    }
    
    min_x = min(current_df$group_min_x)
    max_x = max(current_df$group_max_x)
    
    # Compute x values from min_x to max_x in evenly spaced increments with N points (# rows in current_df)
    N = nrow(current_df)
    x_values = seq(min_x, max_x, length.out = N)
    current_df$x = x_values
    
    # Update the original data frame
    result_df <- rbind(result_df, current_df)
  }
  
  return(result_df)
  
}