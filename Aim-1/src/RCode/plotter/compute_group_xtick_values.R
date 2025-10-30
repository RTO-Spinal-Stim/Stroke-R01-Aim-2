# Function to compute x positions using all factors as grouping factors.
# Plot is grouped from right to left, where the largest group is the final element in grouping_factors.
compute_group_mean_xtick_values <- function(df, grouping_factors) {
  # PURPOSE: Compute x positions for each group in a plot
  # INPUTS:
  #   df: data frame
  #   grouping_factors: grouping factors (in order of grouping, from biggest to smallest)
  #
  # OUTPUTS:
  #   data: data frame with x positions for each group
  #     group_mean_x: group x position
  #     group_min_x: group min x position
  #     group_max_x: group max x position
  library(dplyr)

  # Get factors in df
  factors <- names(df)[sapply(df, is.factor)]

  # Check if all of the grouping factors are factors in the df
  if (!all(grouping_factors %in% factors)) {
    stop("Invalid factor(s). Must be column(s) in data frame")
  }

  # Initialize group_mean_x with 0
  df <- df %>%
    mutate(group_mean_x = 0)

  # Reverse the order of grouping_factors
  grouping_factors <- rev(grouping_factors)
  
  # Compute x positions for each group
  for (i in seq_along(grouping_factors)) {
    # The unique levels of the factor. Should already be in the proper order.
    factor_levels <- levels(df[[grouping_factors[i]]])
    
    # Map factor levels to their order in the data for proper spacing
    level_positions <- match(df[[grouping_factors[i]]], factor_levels) - 1
    
    max_group_mean_x <- max(df$group_mean_x)  # Use max x for proper spacing within each grouping level
    df <- df %>%
      ungroup() %>%
      mutate(group_mean_x = group_mean_x + level_positions * (max_group_mean_x + 1)^(1 + i/20))  # Increase the multiplier for each factor
  }
  
  width <- 0.5
  
  # Optional: Adjust the width of the bars (if needed)
  df <- df %>%
    mutate(group_min_x = group_mean_x - (width/2),
           group_max_x = group_mean_x + (width/2))  # Adjust width of bars
  
  return(df)
}