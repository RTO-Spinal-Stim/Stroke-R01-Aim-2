bar_graph_with_diff_bars <- function(curr_data, comps, grouping_factors, col_name, emmeans=NULL, colors=NULL, x_axis_factor_aliases=NULL,
                                     bar_offsets=0.02, min_y_distance=0.05, text_size=2, fill_factor=NULL, outline_factor=NULL,
                                     x_axis_factors=NULL, vert_bar_height=0.02, text_offset=0.01, patterns=NULL, diff_bars_config=NULL,
                                     diff_bars_factors=NULL, fig_dims=NULL, show_p_values=TRUE, horz_offset=0.008) {
  # Highest level function for the bar graph with significance bars
  bar_xy_data <- bar_graph_xy_data(curr_data, grouping_factors, col_name, emmeans)
  bar_plot <- my_bar_plot(bar_xy_data, grouping_factors, x_axis_factor_aliases, col_name, colors=colors, patterns=patterns, fill_factor=fill_factor, outline_factor=outline_factor, x_axis_factors=x_axis_factors)

  # For the significant difference bars
  comps_bars_xy_data <- diff_bars_xy_data(comps, grouping_factors, bar_xy_data, col_name, diff_bars_config=diff_bars_config, diff_bars_factors=diff_bars_factors)
  diff_bars_plot <- diff_bars_plot(bar_plot, comps_bars_xy_data, bar_xy_data, col_name, min_y_distance=min_y_distance, text_size = text_size, step_increase=bar_offsets, vert_bar_height=vert_bar_height, horz_offset=horz_offset, text_offset=text_offset, show_p_values=show_p_values)
  print(diff_bars_plot$plot)
}

check_equal_lists <- function(list1, list2) {
  all(
    map2_lgl(sort(names(list1)), sort(names(list2)),
             ~identical(list1[[.x]], list2[[.y]]))
  )
}

diff_bars_xy_data <- function(comps, grouping_factors, plotted_df, col_name, interactions=FALSE, is_bar=TRUE, diff_bars_config=NULL, diff_bars_factors=NULL) {
  # comps_df: Pairwise comparisons object
  # grouping_factors: List of factors to group by
  # plotted_df: Data frame with x, ymax, and factor columns, obtained from result$data <- my_bar()
  library(tidyverse)
  comps_df <- as.data.frame(comps)

  # Isolate only the main effects
  all_main_effect_indices <- rep(FALSE, nrow(comps_df))
  for (i in 1:length(grouping_factors)) {
    indices <- filter_main_effect_comparisons_generic(comps_df, i)
    all_main_effect_indices <- all_main_effect_indices | indices$index
  }
  
  main_effects_comps_df <- comps_df[all_main_effect_indices, ]
  # When the "grouping_factors" changes order, it messes up splitting up the contrasts.
  # Therefore, use the order of the factors in the plotted_df to do this.
  plotted_df_names <- names(plotted_df)
  contrast_factor_list <- c()
  for (i in seq_along(plotted_df_names)) {
    if (plotted_df_names[i] %in% grouping_factors) {
      contrast_factor_list <- c(contrast_factor_list, plotted_df_names)
    }
  }
  contrasts_split <- split_contrasts(main_effects_comps_df, contrast_factor_list)
  
  bars_xy <- lapply(seq_along(contrasts_split), function(i) {
    
    contrast <- contrasts_split[[i]]
    
    # Remove all columns except factor_names from plotted_df
    plotted_df_removed <- plotted_df %>%
      select(all_of(grouping_factors))
    
    plotted_df_lists <- plotted_df_removed %>% mutate(new_column = pmap(across(all_of(grouping_factors), as.character), list)) %>% select(new_column)
    plotted_list <- as.list(plotted_df_lists$new_column)
    
    # Find the index of the plotted_list that matches contrast$left
    left_index <- 0
    for (j in seq_along(plotted_list)) {
      if (check_equal_lists(plotted_list[[j]], contrast$left)) {
        left_index <- j
        break
      }
    }
    right_index <- 0
    for (j in seq_along(plotted_list)) {
      if (check_equal_lists(plotted_list[[j]], contrast$right)) {
        right_index <- j
        break
      }
    }
    
    if (left_index == 0 || right_index == 0) {
      return(NULL)
      stop("Could not find the index of the plotted list that matches the contrast")
    }
    
    # Set the color of the diff bars
    default_color <- "grey" # Default for plots that have this metric, but this is just the wrong level.
    for (j in seq_along(diff_bars_config)) {
      if (col_name %in% diff_bars_config[[j]]$metric) {
        config_color <- diff_bars_config[[j]]$color
        factor_name <- setdiff(names(diff_bars_config[[j]]), c("color", "metric"))
        factor_levels <- diff_bars_config[[j]][[factor_name]]
        break()
      } else {
        factor_name <- NULL
        factor_levels <- NULL
      }
    }
    
    color <- default_color
    if (!is.null(factor_name) && factor_name %in% names(contrast$left)) {
      if (contrast$left[[factor_name]] %in% factor_levels || contrast$right[[factor_name]] %in% factor_levels) {
        color <- config_color
      }
    } else if (is.null(factor_name)) {
      color <- "black" # Not the right factor, or maybe even the right metric.
    }
    
    # Determine whether to include the bar based on whether this factor is in the include_bars list
    if (!is.null(diff_bars_factors)) {
      for (factor in diff_bars_factors) {
        if (contrast$left[[factor]] != contrast$right[[factor]]) {
          include_bar <- TRUE # Found a main effect of this factor
          break()
        } else {
          include_bar <- FALSE
        }
      }
      if (!include_bar) {
        return(NULL)
      }
    }
    
    returned_df <- data.frame(p=main_effects_comps_df$p.value[i],
                              xleft=plotted_df$x[[left_index]],
                              xright=plotted_df$x[[right_index]],
                              contrast=main_effects_comps_df$contrast[i],
                              color=color)
    return(returned_df)
  })
  
  # Combine the list of data frames into one data frame
  comps_bars_df <- do.call(rbind, bars_xy)
  return(comps_bars_df)
}

diff_bars_plot <- function(plot, comps_bars_df, plotted_df, col_name, p_cutoff=0.05, text_offset=0.01, step_increase=0.1, min_y_distance_to_data=0.02,
                           panel_id=1, text_size=3, vert_bar_height=0.02, horz_offset=0.008, show_p_values=TRUE) {
  # Actually render the bars. Includes determining the y positions of the bars and the text
  # plot: ggplot object
  # comps_bars_df: Data frame with p, xleft, xright, ymax columns
  # p_cutoff: Significance cutoff
  # text_offset: Percent of the y axis range to offset the text
  # step_increase: Percent of the y axis range to increase the y position of each bar
  # min_y_distance: Minimum distance between bars and the data
  comps_bars_df <- comps_bars_df %>% filter(p < p_cutoff)
  comps_bars_df$p <- as.character(round(as.numeric(comps_bars_df$p), 4))
  
  # If the p column is "0", set it to "<.0001"
  comps_bars_df$p <- ifelse(comps_bars_df$p == "0", "<1e-04", comps_bars_df$p)

  if (length(comps_bars_df$p)==0) {
    plot <- plot + theme(
      panel.grid.major.x = element_blank(),  # Remove major vertical grid lines
      panel.grid.minor.x = element_blank()
    )
    return(list(plot=plot, comps_bars_df = comps_bars_df))
  }

  # Extract the y axis limit for this panel
  built_plot <- ggplot2::ggplot_build(plot)
  layout <- built_plot$layout$layout
  y_range <- built_plot$layout$panel_params[[panel_id]]$y.range
  x_range <- built_plot$layout$panel_params[[panel_id]]$x.range

  min_heights <- min_bar_height(plotted_df, comps_bars_df, col_name, min_y_distance_to_data*diff(y_range), step_increase*diff(y_range))
  comps_bars_df$min_y <- min_heights

  # Order comps_bars_df by ascending xleft value, and then by range.
  comps_bars_df <- comps_bars_df %>%
    mutate(range = xright - xleft) %>%
    arrange(range, xleft) %>%
    select(-range)

  comps_bars_df$y_positions <- comps_bars_df$min_y
  # For each row, calculate the minimum height of the bar.
  # Algorithm: 1. Get the bars (from index i to the end) that span the same x range (xstart < xend_current and xstart > xstart_current, or xend > xstart_current and xend < xend_current)
  # 2. Check if those bars from step 1 are below or equal to the current bar. If so, set their height to the current bar's height + step_increase
  # 3. Repeat for each bar (row) in the data frame
  for (i in seq_len(nrow(comps_bars_df))) {
    # Get the current bar's xleft and xright, and y values
    xleft_current <- comps_bars_df$xleft[i]
    xright_current <- comps_bars_df$xright[i]
    y_current <- comps_bars_df$y_positions[i]

    if (i==nrow(comps_bars_df)) {
      break
    }

    # Iterate through subsequent rows to find overlapping bars
    for (j in (i+1):nrow(comps_bars_df)) {
      # Check if the j-th bar overlaps with the i'th bar
      xleft_j <- comps_bars_df$xleft[j]
      xright_j <- comps_bars_df$xright[j]
      y_j <- comps_bars_df$y_positions[j]

      if (xleft_j < xright_current && xright_j > xleft_current) {
        if (y_j <= y_current) {
          comps_bars_df$y_positions[j] <- y_current + step_increase*diff(y_range)
        }
      }
    }
  }

  valid_colors <- c("grey", "black")
  comps_bars_df$color <- factor(comps_bars_df$color, levels=unique(comps_bars_df$color))
  diff_bar_xleft = comps_bars_df$xleft+horz_offset*diff(x_range)
  diff_bar_xright = comps_bars_df$xright-horz_offset*diff(x_range)
  diff_bar_horz_y = comps_bars_df$y_positions
  diff_bar_vert_y = comps_bars_df$y_positions-vert_bar_height*diff(y_range)

  plot <- plot +
    geom_segment(data=comps_bars_df, aes(x=diff_bar_xleft, xend=diff_bar_xright, y=y_positions, yend=y_positions, color=color), inherit.aes = FALSE, show.legend=FALSE) +
    geom_segment(data=comps_bars_df, aes(x=diff_bar_xleft, xend=diff_bar_xleft, y=y_positions, yend=diff_bar_vert_y, color=color), inherit.aes = FALSE, show.legend=FALSE) +
    geom_segment(data=comps_bars_df, aes(x=diff_bar_xright, xend=diff_bar_xright, y=y_positions, yend=diff_bar_vert_y, color=color), inherit.aes = FALSE, show.legend=FALSE) +
    theme(
      panel.grid.major.x = element_blank(),  # Remove major vertical grid lines
      panel.grid.minor.x = element_blank()
    ) +
    scale_color_manual(values = setNames(valid_colors, valid_colors))

  if (show_p_values==TRUE) {
    plot <- plot +
      geom_text(data=comps_bars_df, aes(x=(xleft+xright)/2, y=y_positions+text_offset*diff(y_range), label=p, color=color), inherit.aes = FALSE, size=text_size, show.legend=FALSE, vjust=-0.5)
  }
  return(list(plot = plot, comps_bars_df = comps_bars_df))
}

min_bar_height <- function(vert_bars_df, comps_bars_df, col_name, min_height_above_data, step_between_bars) {
  # Determine the minimum height of the horizontal sig diff bars
  # vert_bars_df: Data frame with x, ymax, and factor columns
  # comps_bars_df: Data frame with p, xleft, xright, ymax columns
  # Returns the minimum height of the bars

  # 1. For each row of comps_bars_df, get the maximum y value for the x values between comps_bars_df's xleft and xright
  # 2. Find the maximum of the y values
  # 3. Return the maximum of the y values
  data_ymax_values <- sapply(seq(nrow(comps_bars_df)), function(i) {
    xleft <- comps_bars_df$xleft[i]
    xright <- comps_bars_df$xright[i]

    if (length(xleft)==0) {
      browser()
    }

    # Get the y values between xleft and xright
    y_values <- vert_bars_df %>%
      filter(x >= xleft, x <= xright) %>%
      pull(paste0(col_name,"_ymax"))

    # Append a zero to the y_values
    y_values <- c(y_values, 0)

    # If there are no y values, error
    if (length(y_values) == 0) {
      stop("No y values found between xleft and xright")
    }

    # Return the maximum of the y values
    return(max(y_values))
  })

  if (min(data_ymax_values) < 0) {
    browser()
    stop("min(data_ymax_values) < 0")
  }

  # Put the bar onto the lowest multiple of the step_between_bars that is at least min_height_above_data above the data
  min_bar_heights <- ceiling((data_ymax_values + min_height_above_data) / step_between_bars) * step_between_bars

  return(min_bar_heights)
}
