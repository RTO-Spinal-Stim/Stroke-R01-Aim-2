plot_all_histograms <- function(data, factor_names, col_name, fill_factor) {
  # Generate histograms for all combinations of factor levels
  levels_list = generate_combinations(data, factor_names)
  for (i in 1:length(levels_list)) {
    levels <- levels_list[[i]]
    filtered_data <- filter_data_by_levels(data, factor_names, levels)
    histogram <- plot_single_histogram(filtered_data, factor_names, levels, col_name, fill_factor)
    print(histogram)
  }
}

plot_single_histogram <- function(data, factor_names, levels, col_name, fill_factor = NULL) {
  # Generate a histogram for the specified data and factor levels
  title_str = "Histogram of "
  for (i in 1:length(factor_names)) {
    title_str = paste0(title_str, factor_names[i], ": ", levels[[i]], ", ")
  }
  # Remove the last two characters
  title_str = substr(title_str, 1, nchar(title_str) - 2)

  if (is.null(fill_factor)) {
    g <- ggplot(data, aes(x = !!sym(col_name))) +
      geom_histogram(bins = 30)
  } else {
    g <- ggplot(data, aes(x = !!sym(col_name), fill = !!sym(fill_factor))) +
      geom_histogram(position = "stack", color = "black", bins = 30)
  }
  g <- g +
    ggtitle(title_wrapper(title_str, 50))
  return(g)
}

title_wrapper <- function(x, width_value) {
  paste(strwrap(x, width = width_value), collapse = "\n")
}
