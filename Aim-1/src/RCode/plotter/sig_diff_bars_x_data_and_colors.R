sig_diff_bars_x_data_and_colors <- function(comps, lmer_model, grouping_factors, plotted_df, col_name, interactions=FALSE, diff_bars_config=NULL, diff_bars_factors=NULL, panel_id=1) {
    # PURPOSE: GET THE X & Y VALUES FOR THE SIGNIFICANT DIFFERENCE BARS
    # INPUTS:
    #   comps: comparison object (output of lmer)
    #   grouping_factors: factors to use for grouping
    #   plotted_df: data frame with the following columns:
    #       - group_mean_x: mean x value for each group
    #       - group_mean_y: mean y value for each group
    #       - group_min_x: min x value for each group
    #       - group_max_x: max x value for each group
    #       - group_min_y: min y value for each group
    #       - group_max_y: max y value for each group
    #   col_name: column name for y data
    #   interactions: include interactions (default: FALSE)
    #   diff_bars_config: configuration rules for significant difference bars
    #       - metrics: metrics to apply this rule to for significant difference bars
    #       - color: color to use for these metrics' significant difference bars
    #       - factor_name: factor to use for this rule
    #       - example TOML config:
    #           [[plots.diff_bars_config]]
    #           metrics = ["metric_name"]
    #           color = "red"
    #           factor_name = ["factor_levels"]
    #   diff_bars_factors: factors to use for significant difference bars (default: last grouping variable only)
    #
    # OUTPUTS:
    #   bars_df: data frame with the following columns:
    #       - left_x: left x value for each bar
    #       - right_x: right x value for each bar
    #       - y: y value for each bar
    #       - p_value: p value for each bar

    library(tidyverse)
    comps_df <- as.data.frame(comps)

    browser()

    # Initialize diff_bars_config if it is NULL
    if (is.null(diff_bars_config)) {
        diff_bars_config <- list()
    }

    # Initialize diff_bars_factors if it is NULL
    if (is.null(diff_bars_factors)) {
        diff_bars_factors <- grouping_factors[length(grouping_factors)]
    }

    # Isolate only the main effects
    # TODO: If the grouping variable does not include all of the fixed effects in the model,
    # then here I should loop over only those indices in the comps_df (from hyp_tests) where the grouping variables are.
    all_main_effect_indices <- rep(FALSE, nrow(comps_df))
    for (i in 1:length(grouping_factors)) {
        indices <- filter_main_effect_comparisons_generic(comps_df, i)
        all_main_effect_indices <- all_main_effect_indices | indices$index
    }
    main_effects_comps_df <- comps_df[all_main_effect_indices, ]

    # Split the comparisons into the different factors
    # When the "grouping_factors" changes order, it messes up splitting up the contrasts.
    # Therefore, use the order of the factors in the plotted_df to do this.
    # plotted_df_names <- names(plotted_df)
    # contrast_factor_list <- c()
    # for (i in seq_along(plotted_df_names)) {
    #     if (plotted_df_names[i] %in% grouping_factors) {
    #         contrast_factor_list <- c(contrast_factor_list, plotted_df_names[i])
    #     }
    # }
    
    # The contrasts were originally split in the hyp_tests() function using the factors from the model.
    # So get them again from the same source to be in the same order.
    contrast_factor_list <- get_fixed_effects_from_model(lmer_model)

    # Perform the contrast split
    contrasts_split <- split_contrasts(main_effects_comps_df, contrast_factor_list) 

    bars_xy <- lapply(seq_along(contrasts_split), function(i) {
    
        browser()
        contrast <- contrasts_split[[i]]
        
        # Remove all columns except factor_names from plotted_df
        plotted_df_removed <- plotted_df %>%
        select(all_of(contrast_factor_list))
        
        plotted_df_lists <- plotted_df_removed %>% mutate(new_column = pmap(across(all_of(contrast_factor_list), as.character), list)) %>% select(new_column)
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
        
        # browser()
        # Set the color of the diff bars
        default_color <- "grey" # Default for plots that have this metric, but this is just the wrong level.
        factor_name <- NULL
        factor_levels <- NULL
        for (j in seq_along(diff_bars_config)) {
            if (length(diff_bars_config) > 0 && col_name %in% diff_bars_config[[j]]$metrics) {
                config_color <- diff_bars_config[[j]]$color
                factor_name <- setdiff(names(diff_bars_config[[j]]), c("color", "metrics"))
                factor_levels <- diff_bars_config[[j]][[factor_name]]
                break()
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
                                xleft=plotted_df$group_mean_x[[left_index]],
                                xright=plotted_df$group_mean_x[[right_index]],
                                contrast=main_effects_comps_df$contrast[i],
                                color=color)
    return(returned_df)
  })

  # If the xleft value is larger than the xright value, swap them.
  for (i in seq_along(bars_xy)) {
    if (!is.null(bars_xy[[i]]$xleft) && !is.null(bars_xy[[i]]$xright)) {
      if (bars_xy[[i]]$xleft > bars_xy[[i]]$xright) {
          tmp_left <- bars_xy[[i]]$xleft
          tmp_right <- bars_xy[[i]]$xright
          bars_xy[[i]]$xleft <- tmp_right
          bars_xy[[i]]$xright <- tmp_left
      }
    }
  }

  # Combine the list of data frames into one data frame
  comps_bars_df <- do.call(rbind, bars_xy)
  return(comps_bars_df)

}