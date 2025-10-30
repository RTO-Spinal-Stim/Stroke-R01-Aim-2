# Helper function to generate LaTeX table for a single factor
generate_row_one_factor <- function(var_name, emmeans, pairwise_comps, n_decimals, name_mapping, n_summary_types, is_first_line_of_var, var_type = NULL, summary_type = "Mean") {
  # Extract levels from emmeans object
  levels <- unlist(pairwise_comps[[var_name]]@model.info$xlev)

  # Fill emmeans values
  emm_df <- as.data.frame(emmeans[[var_name]])
  if (n_summary_types==1) {
    row_data <- c(var_name, summary_type)
  } else {
    if (is_first_line_of_var) {
      row_data <- c(sprintf("\\multirow{%i}{%imm}{%s}", n_summary_types, round(n_summary_types * 12), var_type), summary_type)
    } else {
      row_data <- c("", summary_type)
    }
  }
  emmean_row <- c()
  for (lvl in levels) {
    level_emm <- emm_df[emm_df == lvl,]
    emmean_row <- c(emmean_row, format_emmean(level_emm$emmean, level_emm$lower.CL, level_emm$upper.CL, n_decimals))
  }
  row_data <- c(row_data, emmean_row)

  # Fill pairwise comparisons
  comparisons <- combn(levels, 2)
  comps_df <- as.data.frame(pairwise_comps[[var_name]])
  comparison_row <- c()
  for (i in 1:ncol(comparisons)) {
    lvl1 <- comparisons[1, i]
    lvl2 <- comparisons[2, i]
    # Ensure correct matching by using the pair names in contrast
    contrast_name <- paste0(lvl1, " - ", lvl2)
    # Assuming comps_df is a data frame containing the contrasts and p-values
    p_val <- comps_df[comps_df$contrast == contrast_name, "p.value"]
    comparison_row <- c(comparison_row, format_pvalue(p_val))

  }
  row_data <- c(row_data, comparison_row)

  return(row_data)
}

generate_row_two_factors <- function(var_name, emmeans_list, pairwise_comps, n_decimals, name_mapping, n_summary_types, is_first_line_of_var, var_type, summary_type) {
  levels <- pairwise_comps[[var_name]]@model.info$xlev
  factor_names <- names(levels)

  row_factor_name <- factor_names[1]
  col_factor_name <- factor_names[2]

  row_levels <- unlist(pairwise_comps[[var_name]]@model.info$xlev[[row_factor_name]])
  col_levels <- unlist(pairwise_comps[[var_name]]@model.info$xlev[[col_factor_name]])

  # Set up the data frames
  emm_df <- as.data.frame(emmeans_list[[var_name]])
  comps_df <- as.data.frame(pairwise_comps[[var_name]])

  # Initialize the output rows
  rows_data <- list()
  for (row_level in row_levels) {
    if (is_first_line_of_var) {
      row_data <- c(sprintf("\\multirow{%i}{%imm}{%s}", n_summary_types*(length(row_levels)+length(combn(row_levels,2))), round(n_summary_types * length(row_levels) * 12), var_type))
    } else {
      row_data <- c("")
    }
    # Emmeans
    col_combns <- combn(col_levels, 2)
    row_data <- c(row_data, name_mapping[[row_factor_name]][[row_level]])
    for (col_level in col_levels) {
      level_emm <- emm_df[emm_df[[row_factor_name]] == row_level & emm_df[[col_factor_name]] == col_level, ]
      row_data <- c(row_data, format_emmean(level_emm$emmean, level_emm$lower.CL, level_emm$upper.CL, n_decimals))
    }
    # P-values
    for (i in 1:ncol(col_combns)) {
      lvl1 <- paste(row_level, col_combns[1, i])
      lvl2 <- paste(row_level, col_combns[2, i])
      # Ensure correct matching by using the pair names in contrast
      contrast_name <- paste0(lvl1, " - ", lvl2)
      # Assuming comps_df is a data frame containing the contrasts and p-values
      p_val <- comps_df[comps_df$contrast == contrast_name, "p.value"]
      row_data <- c(row_data, format_pvalue(p_val))
    }

    rows_data <- c(rows_data, list(row_data))
    is_first_line_of_var <- FALSE
  }

  # Do the pairwise comparisons for the row levels
  row_combns <- combn(row_levels, 2)
  n_columns <- 2 + length(col_levels) + ncol(combn(col_levels, 2))
  for (i in 1:ncol(row_combns)) {
    row_data <- c("",
                  paste0(
                    "\\textbf{",
                    name_mapping[[row_factor_name]][[row_combns[1, i]]], " vs. ",
                    name_mapping[[row_factor_name]][[row_combns[2, i]]],
                    "}"
                  )
                )
    for (col_level in col_levels) {
      lvl1 <- paste(row_combns[1, i], col_level)
      lvl2 <- paste(row_combns[2, i], col_level)
      # Ensure correct matching by using the pair names in contrast
      contrast_name <- paste0(lvl1, " - ", lvl2)
      # Assuming comps_df is a data frame containing the contrasts and p-values
      p_val <- comps_df[comps_df$contrast == contrast_name, "p.value"]
      # Corrected line for generating row_data
      row_data <- c(row_data,
        format_pvalue(p_val)
      )
    }

    row_data <- c(row_data, rep("-", n_columns - length(row_data))) # Add the "-" at the end of the row

    rows_data <- c(rows_data, list(row_data))
  }

  return (rows_data)
}


# Make the table
generate_latex_table <- function(pairwise_comps, emmeans, name_mapping = NULL, vars_list = NULL, n_decimals=3) {
  # If no vars_list is provided, then assumes that there is only one summary type per variable.
  if (is.null(vars_list)) {
    vars_list <- list()
    for (var_name in names(pairwise_comps)) {
      vars_list[[var_name]] <- list()
      vars_list[[var_name]][["Mean"]] <- var_name
    }
  }
  pairs_df <- as.data.frame(pairwise_comps)
  num_levels_factor1 <- length(pairwise_comps[[names(pairwise_comps)[1]]]@model.info$xlev)
  # Initialize the table.
  table_data <- vector(mode = "list", length = length(names(vars_list)) * num_levels_factor1)
  var_num <- 0
  for (var_type in names(vars_list)) {
    n_summary_types <- length(vars_list[[var_type]])
    is_first_line_of_var <- TRUE
    for (summary_type in names(vars_list[[var_type]])) {
      var_name <- vars_list[[var_type]][[summary_type]]

      if (!var_name %in% names(pairwise_comps)) {
        warning(paste0("Variable ", var_name, " not found in pairwise comparisons. Skipping."))
        next
      }

      # browser()
      var_num <- var_num + 1

      if (var_num==1) {
        levels <- pairwise_comps[[var_name]]@model.info$xlev
        factor_names <- names(levels)
        num_factors <- length(levels)
        if (num_factors == 1) {
          header_rows <- create_header_rows(unlist(levels), name_mapping, num_factors, factor_names)
        } else {
          level_name <- names(levels)[2]
          # browser()
          header_rows <- create_header_rows(levels[[2]], name_mapping, num_factors, factor_names[2])
        }
        table_data <- header_rows
        row_num <- length(header_rows) + 1
      }
      if (num_factors == 1) {
        # Generate table for single factor
        row_data <- generate_row_one_factor(var_name, emmeans_list, pairwise_comps, n_decimals, name_mapping, n_summary_types, is_first_line_of_var, var_type, summary_type)
        table_data[[row_num]] <- row_data
        row_num <- row_num  + 1
      } else if (num_factors == 2) {
        # Generate table for two factors
        rows_data <- generate_row_two_factors(var_name, emmeans_list, pairwise_comps, n_decimals, name_mapping, n_summary_types, is_first_line_of_var, var_type, summary_type)
        # Assign each element of rows_data to table_data starting from row_num
        for (i in seq_along(rows_data)) {
          table_data[[row_num]] <- rows_data[[i]]
          row_num <- row_num + 1
        }
      }

      is_first_line_of_var <- FALSE
    }
  }
  footer_rows <- create_footer_rows()
  table_data <- c(table_data, footer_rows)

  # Convert the vector of vectors table_data to a vector of strings
  for (i in (length(header_rows)+1):(length(table_data)-length(footer_rows))) {
    table_data[[i]] <- paste0("           ", paste(paste(table_data[[i]], collapse=" & "), "\\\\")) # Add the end of line character
  }
  return(table_data)
}

create_footer_rows <- function() {
  lines <- list()
  lines[[1]] <- "            \\bottomrule"
  lines[[2]] <- "            \\end{tabular}"
  lines[[3]] <- "      \\end{adjustbox}"
  lines[[4]] <- "      \\caption[Short caption]{Long caption}"
  lines[[5]] <- "      \\label{table:label}"
  lines[[6]] <- "\\end{table}"
  lines[[7]] <- "\\FloatBarrier"
  return (lines)
}

create_header_rows <- function(levels, name_mapping, num_factors, factor_name = NULL) {
  num_levels <- length(levels)
  n_pairwise <- num_levels * (num_levels - 1) / 2
  n_columns <- num_levels + n_pairwise + 2 # +1 for the variable name, +1 for the summary metric
  lines <- list()
  lines[[1]] <- "\\begin{table}[htbp]"
  lines[[2]] <- "    \\begin{adjustbox}{max width=1.1\\textwidth,center}"
  if (num_factors==1) {
    lines[[3]] <- sprintf("        \\begin{tabular}{lc*{%i}{c}}", n_columns - 2)
  } else {
    lines[[3]] <- sprintf("        \\begin{tabular}{lc*{%i}{c}}", n_columns - 2)
  }
  lines[[4]] <- "            \\toprule"
  if (is.null(factor_name)) {
    stop("factor_name must be provided when num_factors > 1")
  }
  if (num_factors==1) {
    lines[[5]] <- sprintf(
      "           \\multirow{2}{25mm}{Parameter} & \\multirow{2}{25mm}{} & \\multicolumn{%i}{c}{\\textbf{Marginal means (95\\%% CL)}} & \\multicolumn{%i}{c}{\\textbf{Post-hoc pairwise comparisons}} \\\\",
      num_levels, n_pairwise
    )
    lines[[6]] <- sprintf("           \\cmidrule(lr){3-%i} \\cmidrule(lr){%i-%i}", num_levels+2, num_levels+3, n_columns)
  } else {
    lines[[5]] <- sprintf(
      "           \\multirow{2}{25mm}{Parameter} & \\multirow{2}{25mm}{%s} & \\multicolumn{%i}{c}{\\textbf{Marginal means (95\\%% CL)}} & \\multicolumn{%i}{c}{\\textbf{Post-hoc pairwise comparisons}} \\\\",
      factor_name, num_levels, n_pairwise
    )
    lines[[6]] <- sprintf("           \\cmidrule(lr){3-%i} \\cmidrule(lr){%i-%i}", num_levels+2, num_levels+3, n_columns)
  }
  name_mapping <- name_mapping[[factor_name]]
  short_levels_combns <- combn(levels, 2, function(x) paste0(name_mapping[[x[1]]], " vs. ", name_mapping[[x[2]]]))
  short_levels <- sapply(levels, function(x) name_mapping[[x]])
  if (num_factors==1) {
    lines[[7]] <- paste(paste(c("           ", "", paste0("\\textbf{", short_levels, "}"), paste0("\\textbf{", short_levels_combns, "}")), collapse = " & "), "\\\\")
  } else {
    lines[[7]] <- paste(paste(c("           ", "", paste0("\\textbf{", short_levels, "}"), paste0("\\textbf{", short_levels_combns, "}")), collapse = " & "), "\\\\")
  }
  # Replace every underscore with a space in lines[[7]]
  lines[[7]] <- gsub("_", " ", lines[[7]])
  lines[[8]] <- "           \\bottomrule"
  return(lines)
}

# Format the emmean value
format_emmean <- function(emmean, lower_cl, upper_cl, n_decimals) {
  # Create a format string dynamically based on n_decimals
  format_string <- paste0("\\makecell{%.", n_decimals, "f \\\\ (%.", n_decimals, "f, %.", n_decimals, "f)}")

  # Use sprintf with the dynamic format string
  sprintf(format_string, emmean, lower_cl, upper_cl)
}

# Helper function to format p-values
format_pvalue <- function(p_val) {
  if (is.na(p_val)) {
    "-"
  } else if (p_val < 0.0001) {
    "\\textbf{<0.0001}"
  } else if (p_val < 0.05) {
    sprintf("\\textbf{%.4f}", p_val)
  } else {
    sprintf("%.4f", p_val)
  }
}
