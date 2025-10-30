read_data <- function(data_file_path, factors_col_names) {
  # Read in the data, omitting NaN values.

  library(readr)
  conflicted::conflicts_prefer(dplyr::filter)
  data_in <- read_csv(data_file_path)

  # Ensure that any complex numbers are converted to real numbers from characters
  for (col_name in names(data_in)) {
    if (is.character(data_in[[col_name]]) && any(grepl("\\+0i$", data_in[[col_name]]))) {
      data_in[[col_name]] <- as.numeric(gsub("\\+0i$", "", data_in[[col_name]]))
    }
  }

  # Set all factor columns as factors
  for (col_name in factors_col_names) {
    if (!col_name %in% colnames(data_in)) {
      next()
    }
    # Remove rows with NaN values for this factor column
    data_in <- data_in[!is.na(data_in[[col_name]]), ]
    # Ensure that there are no spaces in the column names
    # This is important for the p-values table.
    col_name_clean = gsub(" ", "_", col_name)
    data_in[[col_name_clean]] <- as.factor(data_in[[col_name]])
    if (is.complex(data_in[[col_name_clean]])) {
      data_in[[col_name_clean]] <- Re(data_in[[col_name_clean]])
    }
  }

  return(data_in)
}


curr_col_data <- function(all_data, col_name, iter_col_names) {
  # Get the data for the current column of interest & the iteration columns
  all_cols <- append(iter_col_names, col_name)
  curr_data <- all_data[all_cols]
  # Remove NaN rows
  # browser()
  nan_or_na_indices = is.na(curr_data[[col_name]]) | is.nan(curr_data[[col_name]])
  curr_data <- curr_data[!nan_or_na_indices, ]
  return(curr_data)
}


generate_combinations <- function(data, factor_names) {
  # Generate a list of lists containing all possible combinations of factor levels
  
  # Ensure the factor names exist in the data frame
  factor_names <- intersect(factor_names, names(data))
  
  # Extract levels for each specified factor
  factors_list <- lapply(factor_names, function(factor_name) {
    levels(data[[factor_name]])
  })
  
  names(factors_list) <- factor_names # Name the list elements with their corresponding factor names
  combinations_df <- do.call(expand.grid, factors_list) # Generate all combinations using expand.grid()
  combinations_list_named <- apply(combinations_df, 1, as.list) # Convert the data frame to a list of lists
  combinations_list <- lapply(combinations_list_named, function(x) unname(unlist(x))) # Remove the names from the list elements
  
  return(combinations_list)
}


filter_data_by_levels <- function(data, factor_names, levels) {
  # Filter the data frame to only include rows where the specified factors are at the specified levels
  for (i in seq_along(factor_names)) {
    factor_name <- factor_names[i]
    data <- data[data[[factor_name]] == levels[i], ]
  }
  return(data)
}

# Return the names of the fixed effects given the lmer model.
get_fixed_effects_from_model <- function(model) {
  # Assumes that the response variable is always first, and that the order of the fixed effects is preserved relative to how the model was specified.
  random_effects <- names(ranef(model))
  fixed_effects_raw <- names(model@frame)
  fixed_effects <- setdiff(fixed_effects_raw[2:length(fixed_effects_raw)], random_effects)
  return(fixed_effects)
}

# Function to count the maximum number of decimal places in a column
max_decimal_places <- function(data, column_name) {
  # Ensure the specified column is numeric
  if (!is.numeric(data[[column_name]])) {
    stop("The specified column is not numeric.")
  }
  
  # Convert the numeric values to character to analyze the decimal part
  decimal_counts <- sapply(data[[column_name]], function(x) {
    # Split on the decimal point
    parts <- strsplit(as.character(x), "\\.")[[1]]
    # If there is a decimal part, return its length; otherwise, return 0
    if (length(parts) > 1) {
      nchar(parts[2])
    } else {
      0
    }
  })
  
  # Return the maximum number of decimal places
  max(decimal_counts, na.rm = TRUE)
}

split_contrasts <- function(df, factor_names) {
  # Separate the contrast column into two separate columns for each comparison side
  comparisons <- data.frame(do.call(rbind, strsplit(as.character(df$contrast), " - ")), stringsAsFactors = FALSE)
  colnames(comparisons) <- c("left", "right")
  
  # Split each side's names by space and assign them to lists with names from factor_names
  split_comparisons <- lapply(1:nrow(comparisons), function(i) {
    # Split the 'left' and 'right' sides into separate elements
    left_names <- strsplit(comparisons$left[i], " ")[[1]]
    right_names <- strsplit(comparisons$right[i], " ")[[1]]
    
    # Create empty named lists for left and right
    left_list <- list()
    right_list <- list()
    
    # Ensure correct assignment of levels to factor names
    for (j in 1:length(left_names)) {
      left_list[[factor_names[j]]] <- left_names[j]
      right_list[[factor_names[j]]] <- right_names[j]
    }
    
    # Return the list of comparisons with correctly assigned factor levels
    list(
      left = left_list,
      right = right_list
    )
  })

  return(split_comparisons)
}


# Generic function to filter comparisons where only one factor changes
filter_main_effect_comparisons_generic <- function(df, index) {
  # Separate the contrast column into two separate columns for each comparison side
  comparisons <- data.frame(do.call(rbind, strsplit(as.character(df$contrast), " - ")), stringsAsFactors = FALSE)
  colnames(comparisons) <- c("left", "right")

  split_comparisons <- data.frame(
    left = I(lapply(strsplit(comparisons$left, " "), unlist)),
    right = I(lapply(strsplit(comparisons$right, " "), unlist))
  )

  # Initialize a logical vector of the length of split_comparisons
  index_factor_changed <- rep(FALSE, nrow(split_comparisons))
  for (i in 1:nrow(split_comparisons)) {
    # Check if only one factor changes between the two sides of the comparison
    num_differences <- sum(split_comparisons$left[[i]] != split_comparisons$right[[i]])
    index_factor_changed[i] <- num_differences == 1 & index %in% which(split_comparisons$left[[i]] != split_comparisons$right[[i]])
  }

  return(list(index = index_factor_changed, comparisons = split_comparisons))
}

remove_levels <- function(data, factor_name, levels_to_remove) {
  # Remove the specified levels from the specified factors
  data <- data[!(data[[factor_name]] %in% levels_to_remove), ]
  data[[factor_name]] <- droplevels(data[[factor_name]]) # Remove unused levels
  # Remove the NA values
  data <- data[!is.na(data[[factor_name]]), ]
  return(data)
}
