collapse_data <- function(df, collapse_factors, func = "mean") {
    # PURPOSE: Collapse data by factors and calculate summary statistics
    # INPUTS:
    #   df: data frame
    #   collapse_factors: factors to collapse data by
    #   func: summary statistic to calculate (default = "mean")
    #
    # OUTPUTS:
    #   collapsed_df: collapsed data frame

    if (!func %in% c("mean", "median", "sum", "sd", "min", "max", "n")) {
        stop("Invalid function. Must be one of: mean, median, sum, sd, min, max, n")
    }

    if (length(collapse_factors) == 0) {
        return(df)
    }

    if (!all(collapse_factors %in% names(df))) {
        stop("Invalid factor(s). Must be column(s) in data frame")
    }

    # Initialize functions
    funcs <- list()
    funcs$"mean" <- mean
    funcs$"median" <- median
    funcs$"sum" <- sum
    funcs$"sd" <- sd
    funcs$"min" <- min
    funcs$"max" <- max
    funcs$"n" <- length

    # Collapse data
    collapsed_df <- df %>%
        group_by_at(collapse_factors) %>%
        summarise_all(funcs[[func]]) %>%
        ungroup()
    return(collapsed_df)
}