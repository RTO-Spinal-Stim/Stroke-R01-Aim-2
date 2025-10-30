# Function to extract plot factors from an lmer model
extract_plot_factors_from_lmer <- function(model) {
  # Extract fixed and random effects
  random_effects <- names(ranef(model))
  fixed_effects <- get_fixed_effects_from_model(model)

  # Determine factors for plot based on their role in the model
  # Assume the first fixed effect is for the x-axis
  x_axis_factor <- fixed_effects[1]

  # Use the first random effect for coloring
  if (length(random_effects) > 0) {
    color_factor <- random_effects[1]
  } else {
    color_factor <- NULL
  }

  # Use the remaining fixed effects (if available) for faceting
  if (length(fixed_effects) > 2) {
    facet_factors <- fixed_effects[2:length(fixed_effects)]
  } else if (length(fixed_effects) > 1) {
    facet_factors <- fixed_effects[2]
  } else {
    facet_factors <- NULL
  }

  return(list(x_axis_factor = x_axis_factor, color_factor = color_factor, facet_factors = facet_factors))
}

# Updated plotting function with automatic factor selection
# color_factor: Random effect to use for coloring points
# facet_factors: Fixed effects to use for faceting
# x_axis_factor: Fixed effect to use for x-axis
# task_order: Order of tasks for x-axis
line_plot_from_lmer <- function(data, col_name, model, task_order = NULL, point_size = 3) {
  library(dplyr)
  library(ggplot2)
  # Extract factors from the lmer model
  plot_factors <- extract_plot_factors_from_lmer(model)

  x_axis_factor <- plot_factors$x_axis_factor
  color_factor <- plot_factors$color_factor
  facet_factors <- plot_factors$facet_factors

  # Check if task order is provided and reorder the factor levels
  if (!is.null(task_order) && !is.null(x_axis_factor)) {
    data[[x_axis_factor]] <- factor(data[[x_axis_factor]], levels = task_order)
  }

  # Calculate the mean Y values for each combination of factors
  grouping_vars <- c(color_factor, x_axis_factor, facet_factors)
  grouping_vars <- grouping_vars[!is.null(grouping_vars)]  # Remove NULL values

  means_data <- data %>%
    group_by(across(all_of(grouping_vars))) %>%
    summarise(mean_Y = mean(!!sym(col_name)), .groups = "drop")

  # Create the group aesthetic
  group_aes <- if (!is.null(facet_factors)) {
    syms(c(color_factor, facet_factors))
  } else {
    sym(color_factor)
  }

  # Create the base ggplot
  p <- ggplot(data, aes(x = !!sym(x_axis_factor), y = !!sym(col_name))) +
    geom_point(aes(color = !!sym(color_factor)), size = point_size, alpha = 0.7, position = position_dodge(width=0.5)) +  # Add points colored by specified factor
    geom_line(data = means_data, aes(x = !!sym(x_axis_factor), y = mean_Y, group = interaction(!!!group_aes), color = !!sym(color_factor)), linewidth = 1, position = position_dodge(width=0.5)) +  # Add lines for mean values
    scale_x_discrete(name = x_axis_factor) +  # Set x-axis to show the selected factor
    scale_y_continuous(name = col_name) +  # Set y-axis label
    theme_minimal() +  # Minimal theme
    theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels if needed

  # Add facets if specified
  if (!is.null(facet_factors)) {
    if (length(facet_factors) == 2) {
      # Use facet_grid for two facet variables
      p <- p + facet_grid(as.formula(paste(facet_factors[1], "~", facet_factors[2])))
    } else if (length(facet_factors) == 1) {
      # Use facet_wrap for a single facet variable
      p <- p + facet_wrap(as.formula(paste("~", facet_factors[1])))
    }
  }

  # Add color legend label if specified
  if (!is.null(color_factor)) {
    p <- p + labs(color = color_factor)
  }

  print(p)
}


bar_plot_from_lmer <- function(data, col_name, model, pairwise_comps, task_order = NULL) {
  # Extract factors from the lmer model
  plot_factors <- extract_plot_factors_from_lmer(model)

  x_axis_factor <- plot_factors$x_axis_factor
  color_factor <- plot_factors$color_factor
  facet_factors <- plot_factors$facet_factors

  # Check if task order is provided and reorder the factor levels
  if (!is.null(task_order) && !is.null(x_axis_factor)) {
    data[[x_axis_factor]] <- factor(data[[x_axis_factor]], levels = task_order)
  }

  # Calculate the mean Y values for each combination of factors
  grouping_vars <- c(x_axis_factor, facet_factors)
  grouping_vars <- grouping_vars[!is.null(grouping_vars)]  # Remove NULL values

  means_data <- data %>%
    group_by(across(all_of(grouping_vars))) %>%
    summarise(mean_Y = mean(!!sym(col_name)),
              se_Y = sd(!!sym(col_name)) / sqrt(n()), # Standard error calculation
              .groups = "drop")

  # Create the base ggplot for a bar plot
  p <- ggplot(means_data, aes(x = !!sym(x_axis_factor), y = mean_Y, fill = !!sym(x_axis_factor))) +
    geom_bar(stat = "identity", position = position_dodge(), width = 0.7) +  # Create bars with dodging for grouped bars
    geom_errorbar(aes(ymin = mean_Y - se_Y, ymax = mean_Y + se_Y),  # Add error bars
                  position = position_dodge(width = 0.9), width = 0.25) +
    scale_x_discrete(name = x_axis_factor) +  # Set x-axis to show the selected factor
    scale_y_continuous(name = col_name) +  # Set y-axis label
    theme_minimal() +  # Minimal theme
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "none") +  # Rotate x-axis labels if needed
    guides(fill = "none")

  # Add facets if specified
  if (!is.null(facet_factors)) {
    if (length(facet_factors) == 2) {
      # Use facet_grid for two facet variables
      p <- p + facet_grid(as.formula(paste(facet_factors[1], "~", facet_factors[2])))
    } else if (length(facet_factors) == 1) {
      # Use facet_wrap for a single facet variable
      p <- p + facet_wrap(as.formula(paste("~", facet_factors[1])))
    }
  }

  print(p)
}

interaction_plot_from_lmer <- function(data, col_name, model, pairwise_comps, task_order = NULL, x_axis_factor = NULL, color_factor = NULL, facet_factors = NULL) {
  # Extract factors from the lmer model
  plot_factors <- extract_plot_factors_from_lmer(model)

  if (missing(x_axis_factor))   x_axis_factor  <- plot_factors$x_axis_factor
  if (missing(color_factor))    color_factor   <- plot_factors$color_factor
  if (missing(facet_factors))   facet_factors  <- plot_factors$facet_factors



  # Check if task order is provided and reorder the factor levels
  if (!is.null(task_order) && !is.null(x_axis_factor)) {
    data[[x_axis_factor]] <- factor(data[[x_axis_factor]], levels = task_order)
  }

  # Calculate the mean Y values for each combination of factors
  grouping_vars <- c(x_axis_factor, color_factor, facet_factors)
  grouping_vars <- grouping_vars[!is.null(grouping_vars)]  # Remove NULL values

  means_data <- data %>%
    group_by(across(all_of(grouping_vars))) %>%
    summarise(
      mean_Y = mean(!!sym(col_name)),
      se_Y = sd(!!sym(col_name)) / sqrt(n()), # Standard error calculation
      .groups = "drop"
    )

  # Create the base ggplot for an interaction plot
  p <- ggplot(means_data, aes(x = !!sym(x_axis_factor), y = mean_Y, color = !!sym(color_factor), group = !!sym(color_factor))) +
    geom_line(position = position_dodge(width = 0.2)) +  # Add lines for interaction with dodge
    geom_point(size = 3, position = position_dodge(width = 0.2)) +  # Add points for mean values with dodge
    geom_errorbar(aes(ymin = mean_Y - se_Y, ymax = mean_Y + se_Y),  # Add error bars
                  width = 0.2, position = position_dodge(width = 0.2)) +  # Add dodge for error bars
    scale_x_discrete(name = x_axis_factor) +  # Set x-axis to show the selected factor
    scale_y_continuous(name = col_name) +  # Set y-axis label
    theme_minimal() +  # Minimal theme
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          legend.position = "top",
          legend.direction = "horizontal",
          plot.margin = unit(c(2, 2, 2, 2), "in")
          )  # Rotate x-axis labels if needed

  # Add facets if specified
  if (!is.null(facet_factors)) {
    if (length(facet_factors) == 2) {
      # Use facet_grid for two facet variables
      p <- p + facet_grid(as.formula(paste(facet_factors[1], "~", facet_factors[2])))
    } else if (length(facet_factors) == 1) {
      # Use facet_wrap for a single facet variable
      p <- p + facet_wrap(as.formula(paste("~", facet_factors[1])))
    }
  }

  # p <- add_comparison_bars(p, comparisons, facet_vars = facet_factors)

  print(p)
}

