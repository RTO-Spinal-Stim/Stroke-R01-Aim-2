library(ggplot2)     # For creating plots
library(plotly)      # For interactive plots
library(dplyr)       # For data manipulation
library(tidyr)       # For data reshaping
library(stringr)     # For string manipulation

# Read the CSV file
tablePath = "Y:\\LabMembers\\MTillman\\SavedOutcomes\\StrokeSpinalStim\\CycleTable.csv"
data <- read.csv(tablePath)

# Configuration
nCols = 6
saveFolderPath = "Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\Plots\\ScatterPlots_By_Intervention"

# Function to create scatter plots for each outcome variable by speed
create_all_scatter_plots <- function(data) {
  
  # Identify outcome columns (all columns after the first N)
  outcome_cols <- names(data)[nCols+1:ncol(data)]
  outcome_cols <- outcome_cols[!is.na(outcome_cols)]
  
  # List to store all plots
  all_plots <- list()
  
  # Create the plots
  for (outcome in outcome_cols) {
    
    # Create a subset of data for plotting
    plot_data <- data %>%
      select(Subject, Intervention, PrePost, Speed, TrialNum, CycleNum, !!sym(outcome)) %>%
      # Remove rows with missing values in the outcome variable
      filter(!is.na(!!sym(outcome)))
    
    for (speed_val in unique(plot_data$Speed)) {
      
      # Filter for current speed
      speed_data <- plot_data %>%
        filter(Speed == speed_val)
      
      # Create a new variable that combines Subject and PrePost for xticks
      speed_data <- speed_data %>%
        mutate(InterventionPrePost = interaction(Intervention, PrePost, sep = "_"))
      
      # Sort interventions alphabetically and convert to factor with ordered levels
      interventions_post_pre_ordered <- as.character(sort(as.character(unique(speed_data$InterventionPrePost))))
      
      # Move odd indices to even and vice versa to properly order PRE & POST
      interventions_pre_post_ordered <- interventions_post_pre_ordered
      interventions_pre_post_ordered[seq(1, length(interventions_post_pre_ordered), by = 2)] <- interventions_post_pre_ordered[seq(2, length(interventions_post_pre_ordered), by = 2)]
      interventions_pre_post_ordered[seq(2, length(interventions_post_pre_ordered), by = 2)] <- interventions_post_pre_ordered[seq(1, length(interventions_post_pre_ordered), by = 2)]
      
      # Convert InterventionPrePost to a factor with the correct order
      speed_data <- speed_data %>%
        mutate(InterventionPrePost = factor(InterventionPrePost, levels = interventions_pre_post_ordered))
      
      # Create ggplot object with proper subgrouping and alphabetical ordering
      p <- ggplot(speed_data, aes(x = InterventionPrePost, y = !!sym(outcome), 
                                  color = Subject, shape = PrePost,
                                  text = paste("Subject:", Subject, 
                                               "<br>Trial:", TrialNum,
                                               "<br>Cycle:", CycleNum,
                                               "<br>PrePost:", PrePost,
                                               "<br>Value:", round(!!sym(outcome), 4)))) +
        # Use position_dodge to create dodging for each Subject within PrePost
        geom_point(position = position_dodge(width = 0.6), size = 3, alpha = 0.8) +
        scale_x_discrete(name = "Intervention", limits = interventions_pre_post_ordered) +
        labs(title = paste("Scatter Plot of", outcome, "by Intervention and PrePost"),
             subtitle = paste("Speed:", speed_val),
             x = "Intervention",
             y = outcome) +
        theme_bw() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1),
              plot.title = element_text(size = 14),
              plot.subtitle = element_text(size = 12),
              )
      
      # Convert to plotly for interactivity
      p_interactive <- ggplotly(p, tooltip = "text")
      
      # Store plot in list
      plot_name <- paste(outcome, speed_val, sep = "_")
      all_plots[[plot_name]] <- p_interactive
    }

  }
  
  return(all_plots)
  
}

all_plots <- create_all_scatter_plots(data)

# Function to display plots and save them to a specific folder
display_plots <- function(plot_list, output_folder) {
  # Create the output folder if it doesn't exist
  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
    cat("Created output directory:", output_folder, "\n")
  }
  
  for (plot_name in names(plot_list)) {
    # Create a cleaned filename
    clean_name <- str_replace_all(plot_name, "[^a-zA-Z0-9_]", "_")
    filename <- file.path(output_folder, paste0("scatter_plot_", clean_name, ".html"))
    
    # Save the plot
    htmlwidgets::saveWidget(plot_list[[plot_name]], filename, selfcontained = TRUE)
    
    # Print info about saved plot
    cat("Saved plot:", filename, "\n")
  }
}

# Usage: specify the folder where you want to save the plots
display_plots(all_plots, saveFolderPath)