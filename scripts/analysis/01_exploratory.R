# ============================================================================
# Exploratory Data Analysis Functions
# ============================================================================

#' Perform exploratory data analysis
#' @param data Data frame to analyze
#' @return List with summary statistics
perform_eda <- function(data) {
  results <- list()
  
  # Basic statistics
  results$summary <- summary(data)
  
  # Missing value analysis
  results$missing <- colSums(is.na(data))
  results$missing_pct <- round(results$missing / nrow(data) * 100, 2)
  
  # Data types
  results$types <- sapply(data, class)
  
  # Unique values
  results$unique <- sapply(data, function(x) length(unique(x)))
  
  # Numeric variable statistics
  numeric_vars <- names(data)[sapply(data, is.numeric)]
  if (length(numeric_vars) > 0) {
    results$numeric_stats <- data.frame(
      variable = numeric_vars,
      mean = sapply(data[numeric_vars], mean, na.rm = TRUE),
      sd = sapply(data[numeric_vars], sd, na.rm = TRUE),
      min = sapply(data[numeric_vars], min, na.rm = TRUE),
      max = sapply(data[numeric_vars], max, na.rm = TRUE),
      median = sapply(data[numeric_vars], median, na.rm = TRUE)
    )
  }
  
  # Categorical variable frequencies
  categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) || is.character(x))]
  if (length(categorical_vars) > 0) {
    results$categorical_freq <- lapply(data[categorical_vars], table)
  }
  
  return(results)
}

#' Generate EDA report
#' @param data Data frame to analyze
#' @param output_dir Output directory for report
generate_eda_report <- function(data, output_dir = "output/reports") {
  create_dir_if_needed(output_dir)
  
  results <- perform_eda(data)
  
  # Create report file
  report_file <- file.path(output_dir, paste0("eda_report_", get_timestamp(), ".txt"))
  
  sink(report_file)
  cat("=========================================\n")
  cat("Exploratory Data Analysis Report\n")
  cat("Generated:", Sys.time(), "\n")
  cat("=========================================\n\n")
  
  cat("Dataset dimensions:", nrow(data), "rows x", ncol(data), "columns\n\n")
  
  cat("Missing Values:\n")
  print(results$missing_pct)
  cat("\n")
  
  if (!is.null(results$numeric_stats)) {
    cat("Numeric Variables Summary:\n")
    print(results$numeric_stats)
    cat("\n")
  }
  
  if (!is.null(results$categorical_freq)) {
    cat("Categorical Variables Frequencies:\n")
    for (var in names(results$categorical_freq)) {
      cat("\n", var, ":\n", sep = "")
      print(results$categorical_freq[[var]])
    }
  }
  
  sink()
  
  message("EDA report saved to: ", report_file)
  return(results)
}