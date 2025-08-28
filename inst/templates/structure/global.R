# ============================================================================
# Project Name - Main Script
# ============================================================================

# Check and load required libraries
required_packages <- c("data.table", "tidyverse", "openxlsx")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Package", pkg, "is not installed."))
    message(paste("Please install it using: install.packages('", pkg, "')", sep = ""))
  } else {
    library(pkg, character.only = TRUE)
  }
}

# Source utility functions
source("scripts/utils/preprocess_functions.R")
source("scripts/utils/label_functions.R")
source("scripts/utils/helper_functions.R")

# Source analysis functions
for (file in list.files("scripts/analysis", pattern = "\\.R$", full.names = TRUE)) {
  source(file)
}

# Source plot functions
for (file in list.files("scripts/plots", pattern = "\\.R$", full.names = TRUE)) {
  source(file)
}

# Source table functions
for (file in list.files("scripts/tables", pattern = "\\.R$", full.names = TRUE)) {
  source(file)
}

# ============================================================================
# Main Analysis Pipeline
# ============================================================================

run_analysis <- function(
  data_path = "data/raw/data.csv",
  output_dir = "output",
  generate_plots = TRUE,
  generate_tables = TRUE
) {
  
  message("Starting analysis...")
  
  # 1. Load and preprocess data
  data <- load_and_clean_data(data_path)
  
  # 2. Generate tables
  if (generate_tables) {
    create_tables(data, output_dir)
  }
  
  # 3. Generate plots
  if (generate_plots) {
    create_plots(data, output_dir)
  }
  
  message("Analysis complete!")
  
  return(data)
}

# Run if executed directly
if (sys.nframe() == 0) {
  results <- run_analysis()
}