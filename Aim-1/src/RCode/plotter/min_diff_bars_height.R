min_diff_bars_height <- function(vert_bars_df, comps_bars_df, col_name, min_height_above_data, step_between_bars) {
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
      pull("group_max_y")

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