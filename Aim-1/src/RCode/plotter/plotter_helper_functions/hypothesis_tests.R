make_model <- function(data, formula_str, col_name) {

  # Check that the first non-space character is "~"
  trimmed_string <- sub("^\\s+", "", formula_str)
  if (substr(trimmed_string, 1, 1) != "~") {
    stop("The lmer formula string must start with '~'")
  }
  # Format the formula and create the model
  formula <- as.formula(paste0("`", col_name, "`", formula_str))
  model <- lme4::lmer(formula, data = data, REML = FALSE)
  # print(summary(model))
  # print(class(model))
  # print(model@call)
  return (model)
}

get_emmeans <- function(model, emmeans_formula_str, col_name) {
  library(emmeans)
  # Check that the first non-space character is "~"
  trimmed_string <- sub("^\\s+", "", emmeans_formula_str)
  if (substr(trimmed_string, 1, 1) != "~") {
    stop("The emmeans formula string must start with '~'")
  }
  emmeans_formula <- as.formula(emmeans_formula_str)
  marginal_means <- emmeans(model, emmeans_formula)
  return(marginal_means)
}

get_all_combinations <- function(data, factor_names) {
  # Get all possible combinations of fixed effects
  # Assume 'df' is your data frame and 'fixed_effects' is a list of column names

  # Create a list of levels for each fixed effect (factor) in the data frame
  levels_list <- lapply(factor_names, function(fe) {
    if (is.factor(data[[fe]])) {
      levels(data[[fe]])  # Get levels if the column is already a factor
    } else {
      unique(data[[fe]])   # Use unique values if it's not a factor
    }
  })

  # Name the list elements by the fixed effect names
  names(levels_list) <- factor_names
  return(expand.grid(levels_list))
}

hyp_tests <- function(model, data, marginal_means, col_name, column_widths_marginal_means = NULL, column_widths_p_values = unit(c(0.7, 0.2, 0.1), "npc")) {
  # Conduct hypothesis tests; pairwise comparisons of marginal means. Output a table.
  library(gridExtra)
  library(grid)
  library(lme4)

  # TODO: IMPLEMENTA CHECK FOR WHETHER THE MARGINAL_MEANS AND THE LMER MODEL HAVE THE SAME NUMBER OF FIXED EFFECT FACTORS.
  
  if (is.null(column_widths_marginal_means)) {
    n_columns = length(get_fixed_effects_from_model(model)) + 3 # 3 for estimate, lower CL, upper CL
    column_widths_marginal_means <- rep(unit(1/n_columns, "npc"), n_columns)
  }

  # Get how many decimal places to round to.
  n_decimal_places <- max_decimal_places(data, col_name)

  # Get the list of fixed effects for this model.
  factor_names <- get_fixed_effects_from_model(model)

  # Get all possible combinations of fixed effects.
  combinations <- get_all_combinations(data, factor_names)
  valid_contrasts <- get_valid_contrasts(combinations)

  # Pairwise comparisons of only main effect contrasts!
  comps <- contrast(marginal_means, valid_contrasts, adjust = "holm")
  make_marginal_means_table(marginal_means, column_widths_marginal_means, n_decimal_places)
  make_pvals_table(comps, column_widths_p_values, n_decimal_places, factor_names)
  return(comps)
}


# Convert "npc" to approximate character widths
npc_to_char_width <- function(npc_width) {
  total_chars_per_npc <- 70  # Adjust this estimate based on your font and device
  round(npc_width * total_chars_per_npc)
}


# Function to wrap text within a cell to a specified width
wrap_text_table <- function(text, width) {
  wrap_fixed <- function(x, width) {
    # Ensure each element is a character string
    x <- as.character(x)
    wrapped_text <- strsplit(x, paste0("(?<=.{", width, "})"), perl = TRUE)[[1]] # Split the string into chunks of 'width' size
    paste(wrapped_text, collapse = "\n") # Combine the chunks into a single string with newline characters
  }
  sapply(text, wrap_fixed, width = width) # Apply the wrapping function to each element in 'text_list'
}


make_pvals_table <- function(comps, column_widths, n_decimal_places, factor_names, rows_per_page = 8) {
  comps_df_all <- as.data.frame(comps)

  # Remove unneeded columns
  comps_df_all$df <- NULL
  comps_df_all$SE <- NULL
  comps_df_all$t.ratio <- NULL

  names(comps_df_all)[names(comps_df_all) == "p.value"] <- "p"

  # Ensure that the p-values are numeric.
  comps_df_all$p <- as.numeric(as.character(comps_df_all$p))

  # browser()
  # Arrange the tables: main effects first, then interactions
  all_main_effect_indices <- rep(FALSE, nrow(comps_df_all))
  for (i in 1:length(factor_names)) {
    indices <- filter_main_effect_comparisons_generic(comps_df_all, i)
    comps_df <- comps_df_all[indices$index, ]
    title <- paste("Factor ", factor_names[i])
    display_p_values_table(comps_df, column_widths, n_decimal_places, rows_per_page, title)
    all_main_effect_indices <- all_main_effect_indices | indices$index
  }
  # Make the table for interactions
  interaction_indices = !all_main_effect_indices
  comps_df <- comps_df_all[interaction_indices, ]
  title <- "Interactions"
  display_p_values_table(comps_df, column_widths, n_decimal_places, rows_per_page, title)
}

get_valid_contrasts <- function(combinations) {
  # Create a function that checks if only one factor changes between two combinations
  only_one_change <- function(row1, row2) {
    is_one_change <- sum(row1 != row2) == 1
    return(is_one_change)  # True if only one factor is different
  }

  # Initialize an empty list to store valid contrasts
  combinations <- data.frame(lapply(combinations, as.character))
  valid_contrasts <- list()

  # browser()
  # Iterate over all combinations to find pairs where only one factor changes
  for (i in 1:(nrow(combinations)-1)) {
    for (j in (i+1):nrow(combinations)) {
      left <- paste(combinations[i, ], collapse = " ")
      right <- paste(combinations[j, ], collapse = " ")
      levels_of_int <- c("TWW_Latecued LeftSingleSupport", "TWW_Latecued RightSingleSupport")
      if (only_one_change(combinations[i, ], combinations[j, ])) {
        # Construct the contrast name
        contrast_name <- paste(
          paste(combinations[i, ], collapse = " "), "-",
          paste(as.character(combinations[j, ]), collapse = " ")
        )

        # Create a contrast vector of 0s, with 1 and -1 for the valid pair
        contrast_vector <- rep(0, nrow(combinations))
        contrast_vector[i] <- 1
        contrast_vector[j] <- -1

        # Store the contrast name and vector in the list
        valid_contrasts[[contrast_name]] <- contrast_vector
      }
    }
  }

  return(valid_contrasts)
}


display_p_values_table <- function(comps_df, column_widths, n_decimal_places, rows_per_page, title) {
  p_vals <- comps_df$p < 0.05
  colors <- ifelse(p_vals, "lightpink", "white")

  # Round the p-values to 4 decimal places
  comps_df$p <- round(comps_df$p, 4)

  # Convert column widths from "npc" to character widths
  char_widths <- sapply(column_widths, function(w) npc_to_char_width(as.numeric(w)))

  comps_df$estimate <- round(comps_df$estimate, n_decimal_places)

  # Apply wrapping to each column
  wrapped_df <- data.frame(
    Comparison = wrap_text_table(comps_df$contrast, char_widths[1]),
    Estimate = wrap_text_table(comps_df$estimate, char_widths[2]),
    p = wrap_text_table(comps_df$p, char_widths[3]),
    stringsAsFactors = FALSE
  )

  # Split the data frame into chunks of 'rows_per_page'
  split_indices <- split(seq_len(nrow(wrapped_df)), ceiling(seq_len(nrow(wrapped_df)) / rows_per_page))
  split_dfs <- lapply(split_indices, function(indices) wrapped_df[indices, ])
  split_colors <- lapply(split_indices, function(indices) colors[indices])

  # Create and draw tables for each chunk
  for (i in seq_along(split_dfs)) {
    # Define custom theme
    fill_vector <- rep(split_colors[[i]], times = ncol(split_dfs[[i]]))

    core_hjust <- matrix(c(0, 1, 1), nrow = nrow(split_dfs[[i]]), ncol = ncol(split_dfs[[i]]), byrow = TRUE)
    core_x <- matrix(c(0.1, 0.9, 0.9), nrow = nrow(split_dfs[[i]]), ncol = ncol(split_dfs[[i]]), byrow = TRUE)

    colhead_hjust <- c(0, 1, 1)
    colhead_x <- c(0.1, 0.9, 0.9)

    custom_theme <- ttheme_default(
      core = list(
        fg_params = list(
          cex = 0.8,
          hjust = as.vector(core_hjust),
          x = as.vector(core_x)
        ),
        bg_params = list(fill = fill_vector)
      ),
      colhead = list(
        fg_params = list(
          cex = 0.8,
          hjust = colhead_hjust,
          x = colhead_x
        ),
        bg_params = list(fill = "grey", col = "white")
      )
    )
    table_grob <- tableGrob(split_dfs[[i]], theme = custom_theme, widths = column_widths, rows = NULL)

    title_grob <- textGrob(title, gp = gpar(fontsize = 16, fontface = "bold"))

    # Add margins by placing the table inside a viewport with reduced size
    grid.newpage()
    pushViewport(viewport(width = 0.9, height = 0.9))  # Adjust these values for margins
    # grid.arrange(title, table, ncol = 1, heights = c(0.2, 1))
    arranged_grob <- arrangeGrob(grobs = list(title_grob, table_grob), ncol = 1, heights = c(0.05, 1))
    grid.draw(arranged_grob)
    # grid.draw(table_grob)
    popViewport()
  }
}

make_marginal_means_table <- function(marginal_means, column_widths, n_decimal_places, rows_per_page = 10) {
  # Create & save to PDF the table of marginal means. p < 0.05 rows are highlighted in light pink.
  # Columns: {factors}, emmean, lower.CL, upper.CL

  # Extract the marginal means
  marginal_means_df <- as.data.frame(marginal_means)
  marginal_means_df$SE <- NULL
  marginal_means_df$df <- NULL

  factor_names <- setdiff(names(marginal_means_df), c("emmean", "SE", "df", "lower.CL", "upper.CL", "asymp.LCL", "asymp.UCL"))

  char_widths <- sapply(column_widths, function(w) npc_to_char_width(as.numeric(w)))
  
  if ("lower.CL" %in% names(marginal_means_df)) {
    marginal_means_df$asymp.LCL <- marginal_means_df$lower.CL
    marginal_means_df$lower.CL <- NULL
  }
  
  if ("upper.CL" %in% names(marginal_means_df)) {
    marginal_means_df$asymp.UCL <- marginal_means_df$upper.CL
    marginal_means_df$upper.CL <- NULL
  }

  marginal_means_df$emmean <- round(marginal_means_df$emmean, n_decimal_places)
  marginal_means_df$lower.CL <- round(marginal_means_df$asymp.LCL, n_decimal_places)
  marginal_means_df$upper.CL <- round(marginal_means_df$asymp.UCL, n_decimal_places)

  # Wrap the factor names
  wrapped_df_factors <- list()
  for (i in 1:length(factor_names)) {
    factor <- factor_names[i]
    wrapped_df_factors[[factor]] <- wrap_text_table(marginal_means_df[[factor]], char_widths[i])
  }

  # Wrap the data
  prev_num_cols <- length(factor_names)
  wrapped_df_tmp <- data.frame(
    emmean = wrap_text_table(marginal_means_df$emmean, char_widths[prev_num_cols+1]),
    lower.CL = wrap_text_table(marginal_means_df$lower.CL, char_widths[prev_num_cols+2]),
    upper.CL = wrap_text_table(marginal_means_df$upper.CL, char_widths[prev_num_cols+3]),
    stringsAsFactors = FALSE
  )

  # Combine the two data frames
  wrapped_df <- cbind(wrapped_df_factors, wrapped_df_tmp)

  # Split the data frame into chunks of 'rows_per_page'
  split_indices <- split(seq_len(nrow(wrapped_df)), ceiling(seq_len(nrow(wrapped_df)) / rows_per_page))
  split_dfs <- lapply(split_indices, function(indices) wrapped_df[indices, ])

  # Create and draw tables for each chunk
  for (i in seq_along(split_dfs)) {

    # Left justification code from here: https://gist.github.com/zamorarr/dd94cbac7bc21c47a66115428212376e
    core_hjust <- matrix(rep(unit(0, "npc"), ncol(split_dfs[[i]])), nrow = nrow(split_dfs[[i]]), ncol = ncol(split_dfs[[i]]), byrow = TRUE)
    core_x <- matrix(rep(unit(0, "npc"), ncol(split_dfs[[i]])), nrow = nrow(split_dfs[[i]]), ncol = ncol(split_dfs[[i]]), byrow = TRUE)

    # All left justified
    colhead_hjust <- rep(unit(0, "npc"), ncol(split_dfs[[i]]))
    colhead_x <- rep(unit(0.1, "npc"), ncol(split_dfs[[i]]))

    custom_theme <- ttheme_default(
      core = list(
        fg_params = list(
          cex = 0.8,
          hjust = as.vector(core_hjust),
          x = as.vector(core_x)
        )
      ),
      colhead = list(
        fg_params = list(
          cex = 0.8,
          hjust = colhead_hjust,
          x = colhead_x
        )
      )
    )
    table_grob <- tableGrob(split_dfs[[i]], theme = custom_theme, widths = column_widths, rows = NULL)

    # Add margins by placing the table inside a viewport with reduced size
    grid.newpage()
    pushViewport(viewport(width = 0.9, height = 0.9))  # Adjust these values for margins
    grid.draw(table_grob)
    popViewport()
  }
}


summarize_model <- function(model) {
  # Summarize the model

  # Summary of the model
  s <- summary(model)
  # summary <- capture.output(s)
  # cat(summary, sep = "\n")

  # Plot the model
  p <- plot(model)
  print(p)
}
