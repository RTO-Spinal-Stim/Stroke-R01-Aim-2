plot_for_diff_bars <- function(collapsed_df, grouping_factors, col_name, plot_type="scatter",
                                colors=NULL, fill_factor=NULL, outline_factor=NULL, x_axis_factors=NULL, patterns=NULL) {
    # PURPOSE: Plot data in a way that will work with significant difference bars.
    # Does NOT actually plot the significant difference bars.
    # INPUTS:
    #   collapsed_df: data frame properly collapsed. There should be exactly one non-factor numeric column
    #   grouping_factors: grouping factors (in order of grouping, from biggest to smallest)
    #   col_name: column name for y data
    #   plot_type: type of plot (scatter or bar)
    #   colors: colors for each group
    #   fill_factor: factor to use for fill
    #   outline_factor: factor to use for outline
    #   x_axis_factors: factors to use for x axis
    #   patterns: patterns for each group
    #   vert_bar_height: height of vertical bars
    #   text_offset: offset for text
    #   bar_offsets: offset for bars
    #   min_y_distance: minimum distance between y values
    #   text_size: size of text
    #   diff_bars_config: configuration for significant difference bars
    #   diff_bars_factors: factors to use for significant difference bars
    #   fig_dims: dimensions of figure
    #   show_p_values: show p values
    #   horz_offset: horizontal offset for p values
    #
    # OUTPUTS:
    #   result: contains the ggplot object and the data frame
      
    # Check if all of the grouping factors are factors in the df
    factors <- names(collapsed_df)[sapply(collapsed_df, is.factor)]
    if (!all(grouping_factors %in% factors)) {
        stop("Invalid factor(s). Must be column(s) in data frame")
    }
    
    if (length(factors) != length(names(collapsed_df))-1) {
        stop("There should be exactly one non-factor numeric column")
    }
    
    # Check the plot type
    plot_type <- get_plot_type(plot_type)
    
    # Get the X values for the plot
    x_data <- compute_group_mean_xtick_values(collapsed_df, grouping_factors)
    
    # Get the Y values for the plot
    if (plot_type == "bar") {
        y_data <- compute_group_y_values_for_sig_diff_bars(collapsed_df, grouping_factors)
    } else {
        y_data <- compute_group_y_values_for_sig_diff_bars(collapsed_df, grouping_factors)
    }
    
    # Put the "x_mean" column from x_data and "y_mean" column from y_data into the collapsed_df (same factors and number of rows)
    collapsed_df$group_min_x <- x_data$group_min_x
    collapsed_df$group_max_x <- x_data$group_max_x
    collapsed_df$group_mean_x <- x_data$group_mean_x
    collapsed_df$group_mean_y <- y_data$group_mean_y
    collapsed_df$group_min_y <- y_data$group_min_y
    collapsed_df$group_max_y <- y_data$group_max_y
    
    # Get the x & y values that are actually being plotted.
    if (plot_type == "bar") {
        collapsed_df$x <- collapsed_df$group_mean_x
        collapsed_df$y <- collapsed_df$group_mean_y
    } else if (plot_type == "scatter") {
        collapsed_df <- compute_scatter_x_values(collapsed_df, grouping_factors)
        collapsed_df$y <- collapsed_df[[col_name]]
    }
    
    # Plot the data
    if (plot_type == "bar") {
      gp <- my_bar_plot(collapsed_df, grouping_factors, 
                        col_name, colors=colors, patterns=patterns, fill_factor=fill_factor, 
                        outline_factor=outline_factor, x_axis_factors=x_axis_factors)
    } else if (plot_type == "scatter") {
      gp <- my_scatter_plot(collapsed_df, grouping_factors, col_name, fill_factor=fill_factor,                             
                            x_axis_factors=x_axis_factors)
    }
    
    result <- list()
    result$gp <- gp
    result$df <- collapsed_df
    return(result)    
}