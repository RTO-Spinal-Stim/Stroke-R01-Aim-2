my_scatter_plot <- function(df, grouping_factors, col_name, fill_factor=NULL, 
                            x_axis_factors=NULL, shape_factor=NULL, size=3, shape=19, color="black") {
  # PURPOSE: PLOT A SCATTER PLOT COMPATIBLE WITH SIGNIFICANT DIFFERENCE BARS
  # Inputs:
  #   df: data frame with collapsed data
  #   grouping_factors: factors to group by
  #   first_grouping_factor_displayname: display name for first grouping factor
  #   col_name: column name for y values
  #   patterns: patterns for each group
  #   fill_factor: factor to use for fill
  #   outline_factor: factor to use for outline
  #   x_axis_factors: factors to use for x axis
  #   shape_factor: factor to use for shape
  #   size: size of points (default = 3)
  #   shape: shape of points (only used if shape_factor is NULL)
  #
  # Outputs:
  #   gp: ggplot object
  library(ggplot2)

  # Initialize variables
  if (!is.null(fill_factor)) {
    gp <- ggplot(df, aes(x = x, y = y, color = .data[[fill_factor]]))
  } else {
    gp <- ggplot(df, aes(x = x, y = y))
  }

  # By default use all of the grouping factors for the x axis
  if (is.null(x_axis_factors)) {
    x_axis_factors <- grouping_factors
  }

  xlabel <- paste(x_axis_factors, collapse = " * ")

  # Set the geom_point aesthetics
  if (is.null(fill_factor)) {
    gp <- gp + 
      geom_point(
        size = size,
        fill = if (!is.null(color)) color else NULL,
        color = if (!is.null(color)) color else NULL,
        shape = if (!is.null(shape)) shape else NULL
      )
  } else {
    gp <- gp + 
      geom_point(
        size = size,
        shape = shape
      )
  }

  # Run the plot
  gp <- gp +
    scale_x_continuous(
      breaks = df$group_mean_x,
      labels = df[[grouping_factors[length(grouping_factors)]]]
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_blank(),
      axis.title.x = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank()
    ) +
    ylab(col_name) +
    xlab(xlabel)
}