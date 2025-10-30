plot_sig_diff_bars <- function(gp, df, comps, lmer_model, grouping_factors, col_name, emmeans, 
                                vert_bar_height=0.02, text_offset=0.01,
                                min_y_distance=0.05, text_size=2, diff_bars_config=NULL, diff_bars_factors=NULL,
                                fig_dims=NULL, show_p_values=TRUE, horz_offset=0.008, p_cutoff=0.05, step_increase=0.1, panel_id=1) {
    # PURPOSE: Add significant difference bars to a plot
    # INPUTS:
    #   gp: ggplot object
    #   df: data frame with the following columns:
    #       - group_mean_x: mean x value for each group (USED HERE)
    #       - group_mean_y: mean y value for each group
    #       - group_min_x: min x value for each group
    #       - group_max_x: max x value for each group
    #       - group_min_y: min y value for each group
    #       - group_max_y: max y value for each group (USED HERE)
    #       - x: actual value(s) to plot for each group
    #       - y: actual value(s) to plot for each group
    #   comps: comparison object (output of lmer)
    #   grouping_factors: factors to use for grouping
    #   col_name: column name for y data
    #   emmeans: emmeans object
    #   vert_bar_height: height of vertical bars
    #   text_offset: offset for text
    #   min_y_distance: minimum distance between y values
    #   text_size: size of text
    #   diff_bars_config: configuration for significant difference bars
    #   diff_bars_factors: factors to use for significant difference bars
    #   fig_dims: dimensions of figure
    #   show_p_values: show p values
    #   horz_offset: horizontal offset for p values
    #   p_cutoff: p-value cutoff for significance
    #   step_increase: step increase for y values
    #   panel_id: panel id
    #
    # OUTPUTS:
    #   gp: ggplot object

    browser()
    # Get the x data, p-values, and colors for the significant difference bars    
    sig_diff_bars_x_df <- sig_diff_bars_x_data_and_colors(comps, lmer_model, grouping_factors, df, col_name, interactions=FALSE, diff_bars_config=diff_bars_config, diff_bars_factors=diff_bars_factors, panel_id=panel_id)

    # Get the y values for the significant difference bars
    sig_diff_bars_xy_df <- sig_diff_bars_y_data(gp, df, sig_diff_bars_x_df, col_name, p_cutoff=p_cutoff,
                                                step_increase=step_increase, panel_id=panel_id, 
                                                vert_bar_height=vert_bar_height, min_y_distance=min_y_distance)

    # Get the y range in units
    built_plot <- ggplot2::ggplot_build(gp)
    y_range <- built_plot$layout$panel_params[[panel_id]]$y.range
    x_range <- built_plot$layout$panel_params[[panel_id]]$x.range
    
    # Add the significant difference bars to the plot
    valid_colors <- c("grey", "black")
    sig_diff_bars_xy_df$color <- factor(sig_diff_bars_xy_df$color, levels=unique(sig_diff_bars_xy_df$color))
    diff_bar_xleft = sig_diff_bars_xy_df$xleft+horz_offset*diff(x_range)
    diff_bar_xright = sig_diff_bars_xy_df$xright-horz_offset*diff(x_range)
    diff_bar_horz_y = sig_diff_bars_xy_df$y_positions
    diff_bar_vert_y = sig_diff_bars_xy_df$y_positions-vert_bar_height*diff(y_range)

    gp <- gp +
        geom_segment(data=sig_diff_bars_xy_df, aes(x=diff_bar_xleft, xend=diff_bar_xright, y=y_positions, yend=y_positions), color=sig_diff_bars_xy_df$color, inherit.aes = FALSE, show.legend=FALSE) +
        geom_segment(data=sig_diff_bars_xy_df, aes(x=diff_bar_xleft, xend=diff_bar_xleft, y=y_positions, yend=diff_bar_vert_y), color=sig_diff_bars_xy_df$color, inherit.aes = FALSE, show.legend=FALSE) +
        geom_segment(data=sig_diff_bars_xy_df, aes(x=diff_bar_xright, xend=diff_bar_xright, y=y_positions, yend=diff_bar_vert_y), color=sig_diff_bars_xy_df$color, inherit.aes = FALSE, show.legend=FALSE) +
        theme(
            panel.grid.major.x = element_blank(),  # Remove major vertical grid lines
            panel.grid.minor.x = element_blank()
        )

    if (show_p_values==TRUE) {
        gp <- gp +
          geom_text(
            data=sig_diff_bars_xy_df, 
            aes(x=(xleft+xright)/2, y=y_positions+text_offset*diff(y_range), label=p), 
            color=sig_diff_bars_xy_df$color,
            inherit.aes = FALSE, 
            size=text_size, 
            show.legend=FALSE, 
            vjust=-0.5
          )
    }
    return(list(plot = gp, sig_diff_bars_df = sig_diff_bars_xy_df))
}