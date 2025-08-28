# ============================================================================
# Statistical Analysis Functions
# ============================================================================

#' Perform correlation analysis
#' @param data Data frame with numeric variables
#' @param method Correlation method (pearson, spearman, kendall)
#' @return Correlation matrix
correlation_analysis <- function(data, method = "pearson") {
  numeric_data <- data[sapply(data, is.numeric)]
  
  if (ncol(numeric_data) < 2) {
    warning("Not enough numeric variables for correlation analysis")
    return(NULL)
  }
  
  cor_matrix <- cor(numeric_data, use = "complete.obs", method = method)
  return(cor_matrix)
}

#' Perform t-test for group comparisons
#' @param data Data frame
#' @param value_col Name of value column
#' @param group_col Name of grouping column
#' @return T-test results
group_comparison <- function(data, value_col, group_col) {
  groups <- unique(data[[group_col]])
  
  if (length(groups) != 2) {
    warning("T-test requires exactly 2 groups")
    return(NULL)
  }
  
  group1_data <- data[data[[group_col]] == groups[1], value_col]
  group2_data <- data[data[[group_col]] == groups[2], value_col]
  
  result <- t.test(group1_data, group2_data)
  return(result)
}

#' Perform ANOVA for multiple group comparisons
#' @param data Data frame
#' @param value_col Name of value column
#' @param group_col Name of grouping column
#' @return ANOVA results
anova_analysis <- function(data, value_col, group_col) {
  formula_str <- paste(value_col, "~", group_col)
  model <- aov(as.formula(formula_str), data = data)
  return(summary(model))
}

#' Perform linear regression
#' @param data Data frame
#' @param dependent Variable name for dependent variable
#' @param independents Vector of independent variable names
#' @return Linear model object
linear_regression <- function(data, dependent, independents) {
  formula_str <- paste(dependent, "~", paste(independents, collapse = " + "))
  model <- lm(as.formula(formula_str), data = data)
  return(model)
}

#' Generate statistical analysis report
#' @param data Data frame
#' @param output_dir Output directory
statistical_report <- function(data, output_dir = "output/reports") {
  create_dir_if_needed(output_dir)
  
  report_file <- file.path(output_dir, paste0("statistical_report_", get_timestamp(), ".txt"))
  
  sink(report_file)
  cat("=========================================\n")
  cat("Statistical Analysis Report\n")
  cat("Generated:", Sys.time(), "\n")
  cat("=========================================\n\n")
  
  # Correlation analysis
  cor_matrix <- correlation_analysis(data)
  if (!is.null(cor_matrix)) {
    cat("Correlation Matrix:\n")
    print(round(cor_matrix, 3))
    cat("\n")
  }
  
  sink()
  
  message("Statistical report saved to: ", report_file)
}