#!/usr/bin/env Rscript
# ============================================================================
# Run Analysis Script
# ============================================================================

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Set default parameters
data_path <- if (length(args) > 0) args[1] else "data/raw/data.csv"
output_dir <- if (length(args) > 1) args[2] else "output"
generate_plots <- if (length(args) > 2) as.logical(args[3]) else TRUE
generate_tables <- if (length(args) > 3) as.logical(args[4]) else TRUE

# Source the main script
source("global.R")

# Run the analysis
cat("================================================\n")
cat("Starting Analysis\n")
cat("================================================\n")
cat("Data path:", data_path, "\n")
cat("Output directory:", output_dir, "\n")
cat("Generate plots:", generate_plots, "\n")
cat("Generate tables:", generate_tables, "\n")
cat("================================================\n\n")

results <- run_analysis(
  data_path = data_path,
  output_dir = output_dir,
  generate_plots = generate_plots,
  generate_tables = generate_tables
)

cat("\n================================================\n")
cat("Analysis Complete!\n")
cat("================================================\n")
cat("Results saved to:", output_dir, "\n")
cat("Number of records processed:", nrow(results), "\n")
cat("================================================\n")