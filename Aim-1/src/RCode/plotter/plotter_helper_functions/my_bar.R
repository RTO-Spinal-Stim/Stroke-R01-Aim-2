xtick_xcoords <- function(data, grouping_factors, xtick_factors) {

  x_ranges <- data %>%
    group_by(across(all_of(xtick_factors))) %>%
    summarise(xmin = min(x), xmax = max(x), xmean = (max(x) + min(x))/2)

  x_ranges$xticklabels <- apply(x_ranges[, xtick_factors], 1, function(row) {
    paste(row, collapse = " ")
  })

  return(x_ranges)
}

my_bar_plot <- function(data, grouping_factors, x_axis_factor_aliases, col_name, colors = NULL, patterns=NULL, fill_factor = NULL, outline_factor=NULL, x_axis_factors=NULL) {
  # Levels of the lowest grouping factor for labeling individual bars
  levels_lowest_group <- levels(data[[grouping_factors[1]]]) # What to label the individual bars with

  # Initialize ggplot without fill
  if (is.null(fill_factor)) {
    if (length(grouping_factors)>1) {
      fill_factor <- grouping_factors[2]
    }
  }
  if (length(grouping_factors)==1) {
    fill_factor <- NULL
  }
  
  if (!is.null(fill_factor)) {
    gp <- ggplot(data, aes(x = x, y = !!sym(paste0(col_name, "_mean")), fill = !!sym(fill_factor)))  # Base plot
  } else {
    gp <- ggplot(data, aes(x = x, y = !!sym(paste0(col_name, "_mean"))))  # Base plot
  }
  if (is.null(x_axis_factors)) {
    # x_axis_factors <- grouping_factors[length(grouping_factors)]
    x_axis_factors <- grouping_factors[1]
  }
  
  # Get the x-coordinates of the clustering of each bar.
  x_ranges <- xtick_xcoords(data, grouping_factors, x_axis_factors)
  width <- 0.5
  if (is.null(fill_factor)) {
    gp <- gp +
      geom_bar(stat = "identity", width = width, position = position_identity())
  } else {
    if (is.null(outline_factor)) {
      gp <- gp +
        geom_bar(stat = "identity", width = width, position = position_dodge(), color =  "black")
    } else {
      # factor_patterns <- lapply(patterns[[outline_factor]], function(x) if (substr(x, 1, 1) != "#") {paste0("#", x)} else {x})
      gp <- gp +
        geom_bar_pattern(stat = "identity", width = width, position = position_dodge(), color = "black", aes(pattern = !!sym(outline_factor)), pattern_density=0.3, pattern_spacing=0.02) +
        scale_pattern_type_manual(values = unlist(patterns[[outline_factor]]))
    }
  }
  
  # Replace the vector x_ranges$xticklabels with the values from the named list x_axis_factor_aliases, where each name is a value in x_ranges$xticklabels
  # x_ranges$xticklabels <- unname(unlist(x_axis_factor_aliases[x_ranges$xticklabels]))
  
  gp <- gp +
    geom_errorbar(aes(ymin = !!sym(paste0(col_name, "_ymin")), ymax = !!sym(paste0(col_name, "_ymax"))), width = 0.1) +  # Add error bars
    scale_x_continuous(
      breaks = x_ranges$xmean,
      labels = x_ranges$xticklabels) +
    theme_minimal() +
    theme(
      # axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_blank(),
      axis.title.x = element_blank()
    )
  
  if (!is.null(fill_factor)) {
    factor_colors <- lapply(colors[[fill_factor]], function(x) if (substr(x, 1, 1) != "#") {paste0("#", x)} else {x})
    gp <- gp +
      scale_fill_manual(values = factor_colors)
    if (!is.null(outline_factor)) {
      outline_colors <- lapply(colors[[outline_factor]], function(x) if (substr(x, 1, 1) != "#") {paste0("#", x)} else {x})
      gp <- gp +
        scale_color_manual(values = outline_colors) +
        labs(y = col_name, fill = fill_factor, color = outline_factor)
    } else {
      gp <- gp +
        labs(y = col_name, fill = fill_factor)
    }
  } else {
    gp <- gp + labs(y = col_name)
  }
  
  # Return the ggplot object
  return(gp)
}

bar_graph_xy_data <- function(input_data, grouping_factors, col_name, emmeans=NULL) { 
  # PURPOSE: GET THE X AND Y DATA TO PLOT
  # data: A data frame with factor columns and numeric columns
  # numeric columns: ymin, ymax
  # grouping_factors: A character vector of factor column names
  
  if (!col_name %in% colnames(input_data)) {
    stop(sprintf("Column name %s not found in data", col_name))
  }
  
  if (is.null(emmeans)) {
    means_data <- input_data %>%
      group_by(across(all_of(grouping_factors))) %>%
      summarise(across(all_of(col_name), list(mean = mean, sd = sd, ymin = ~ mean(.x) - sd(.x), ymax = ~ mean(.x) + sd(.x))))
  } else {
    means_data <- emmeans %>%
      as.data.frame() %>%
      mutate(
        # Assuming you calculate standard deviation from the original input_data
        sd = input_data %>%
          group_by(across(all_of(grouping_factors))) %>%
          summarise(sd= sd(!!sym(col_name)), .groups = "drop") %>%
          pull(sd),
        !!paste0(col_name, "_ymin") := emmean - sd,  # Calculate ymin
        !!paste0(col_name, "_ymax") := emmean + sd,   # Calculate ymax
        !!paste0(col_name, "_mean") := emmean,  # Rename emmean to col_name_mean
      ) %>%
      select(-emmean)  # Remove emmean column
  }
  
  # Compute x positions using all grouping factors
  bar_x_y <- compute_x_positions(means_data, grouping_factors)
  
  return (bar_x_y)
}


# Function to compute x positions using all factors as grouping factors.
# Plot is grouped from right to left, where the largest group is the final element in grouping_factors.
compute_x_positions <- function(data, grouping_factors) {
  
  if (length(grouping_factors) != sum(sapply(data, is.factor))) {
    stop("The number of grouping factors must match the number of factor columns in the data.")
  }
  
  # Initialize x_base with 0
  data <- data %>%
    mutate(x_base = 0)
  
  # Initialize x position with x_base
  data <- data %>%
    mutate(x = x_base)
  
  # Reverse the order of grouping_factors
  grouping_factors <- rev(grouping_factors)
  
  # Compute x positions with adjustments for each grouping factor
  for (i in seq_along(grouping_factors)) {
    factor_levels <- as.numeric(data[[grouping_factors[i]]]) - 1
    factor_levels <- unique(data[[grouping_factors[i]]])
    
    # Map factor levels to their order in the data for proper spacing
    level_positions <- match(data[[grouping_factors[i]]], factor_levels) - 1
    
    max_base <- max(data$x)  # Use max x for proper spacing within each grouping level
    data <- data %>%
      ungroup() %>%
      mutate(x = x + level_positions * (max_base + 1)^(1 + i/20))  # Increase the multiplier for each factor
  }
  
  # Optional: Adjust the width of the bars (if needed)
  data <- data %>%
    mutate(xend = x + 0.5)  # Adjust width of bars

  data <- data %>% select(-x_base)

  return(data)
}
