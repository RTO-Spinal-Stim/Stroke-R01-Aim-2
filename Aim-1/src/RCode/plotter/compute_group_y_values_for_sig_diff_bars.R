compute_group_y_values_for_sig_diff_bars <- function(df, grouping_factors) {
    # PURPOSE: Compute y data for each group in a plot. This data will be used for significant difference bars.
    # Works for scatter plots, but not bar plots, because this uses each data point rather than error bars.
    # INPUTS:
    #   df: data frame
    #   grouping_factors: grouping factors (in order of grouping, from biggest to smallest)
    #
    # OUTPUTS:
    #   summary_df: data frame with y data for each group
    #     group_mean_y: group y data
    #     group_min_y: group min y data
    #     group_max_y: group max y data
    library(dplyr)

    # Get factors in df
    factors <- names(df)[sapply(df, is.factor)]

    # Check if all of the grouping factors are factors in the df
    if (!all(grouping_factors %in% factors)) {
        stop("Invalid factor(s). Must be column(s) in data frame")
    }
    
    # Get the numeric column name
    numeric_col_name <- names(df)[sapply(df, is.numeric)]
    
    summary_df <- df %>%
      group_by(across(all_of(grouping_factors))) %>%
      summarize(
        group_mean_y = mean(!!sym(numeric_col_name), na.rm = TRUE),
        group_min_y = min(!!sym(numeric_col_name), na.rm = TRUE),
        group_max_y = max(!!sym(numeric_col_name), na.rm = TRUE),
        .groups = "drop"
      ) %>%
      ungroup()

    # Put the summary_df back into the original df
    df <- df %>%
      left_join(summary_df, by = grouping_factors)

    return(df)

}