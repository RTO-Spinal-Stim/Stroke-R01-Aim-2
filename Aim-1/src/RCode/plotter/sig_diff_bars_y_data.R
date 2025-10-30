sig_diff_bars_y_data <- function(gp, df, sig_diff_bars_x_df, col_name, p_cutoff=0.05, vert_bar_height=0.02, min_y_distance_to_data=0.02, step_increase=0.1, panel_id=1) {
    # PURPOSE: Get the y values for the significant difference bars
    # INPUTS:
    #   gp: ggplot object    
    #   df: data frame with the following columns:
    #       - group_mean_x: mean x value for each group
    #       - group_mean_y: mean y value for each group
    #       - group_min_x: min x value for each group
    #       - group_max_x: max x value for each group
    #       - group_min_y: min y value for each group
    #       - group_max_y: max y value for each group
    #   sig_diff_bars_x_df: output of sig_diff_bars_x_data_and_colors
    #   col_name: column name for y data
    #   p_cutoff: p-value cutoff for significance
    #   vert_bar_height: height of vertical bars
    #   min_y_distance_to_data: minimum distance between y values
    #   step_increase: step increase for y values
    #   panel_id: panel id
    library(ggplot2)

    # Filter the comparisons for only the significant p-values
    sig_diff_bars_x_df <- sig_diff_bars_x_df %>% filter(p < p_cutoff)

    # Round the p-values to 4 places
    sig_diff_bars_x_df$p <- as.character(round(as.numeric(sig_diff_bars_x_df$p), 4))

    # If the p column is "0", change it to "<0.0001"
    sig_diff_bars_x_df$p[sig_diff_bars_x_df$p == "0"] <- "<0.0001"

    # If there are no significant differences, return the plot without the significant difference bars
    if (length(sig_diff_bars_x_df$p)==0) {
        gp <- gp + theme(
            panel.grid.major.x = element_blank(),  # Remove major vertical grid lines
            panel.grid.minor.x = element_blank()
        )
        return(list(gp=gp, sig_diff_bars_x_df=sig_diff_bars_x_df))
    }

    # Extract the y axis limit for this panel
    built_plot <- ggplot2::ggplot_build(gp)
    layout <- built_plot$layout$layout
    y_range <- built_plot$layout$panel_params[[panel_id]]$y.range    

    # Get the minimum heights based on the data
    min_heights <- min_diff_bars_height(plotted_df, sig_diff_bars_x_df, col_name, min_y_distance_to_data*diff(y_range), step_increase*diff(y_range))
    sig_diff_bars_x_df$min_y <- min_heights

    # Order sig_diff_bars_x_df by ascending xleft value, and then by range.
    sig_diff_bars_x_df <- sig_diff_bars_x_df %>%
        mutate(range = xright - xleft) %>%
        arrange(range, xleft) %>%
        select(-range)

    sig_diff_bars_x_df$y_positions <- sig_diff_bars_x_df$min_y

    for (i in seq_len(nrow(sig_diff_bars_x_df))) {
        # Get the current bar's xleft and xright, and y values
        xleft_current <- sig_diff_bars_x_df$xleft[i]
        xright_current <- sig_diff_bars_x_df$xright[i]
        y_current <- sig_diff_bars_x_df$y_positions[i]

        if (i==nrow(sig_diff_bars_x_df)) {
            break
        }

        # Iterate through subsequent rows to find overlapping bars
        # If there is an overlapping bar, increase the y value
        for (j in (i+1):nrow(sig_diff_bars_x_df)) {
            # Check if the j-th bar overlaps with the i'th bar
            xleft_j <- sig_diff_bars_x_df$xleft[j]
            xright_j <- sig_diff_bars_x_df$xright[j]
            y_j <- sig_diff_bars_x_df$y_positions[j]

            if (xleft_j < xright_current && xright_j > xleft_current) {
                if (y_j <= y_current) {
                    sig_diff_bars_x_df$y_positions[j] <- y_current + step_increase*diff(y_range)
                }
            }
        }
    }
    return(sig_diff_bars_x_df)

}