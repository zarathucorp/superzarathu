# ============================================================================
# Basic Table Functions (data.table style)
# ============================================================================

library(data.table)
library(magrittr)

#' Create summary table
#' @param data Data frame or data.table
#' @param group_var Grouping variable (optional)
#' @return Summary table
create_summary_table <- function(data, group_var = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  numeric_vars <- names(data)[sapply(data, is.numeric)]
  
  if (is.null(group_var)) {
    # Overall summary
    summary_table <- data[, .(
      Mean = lapply(.SD, mean, na.rm = TRUE),
      SD = lapply(.SD, sd, na.rm = TRUE),
      Min = lapply(.SD, min, na.rm = TRUE),
      Max = lapply(.SD, max, na.rm = TRUE),
      N = lapply(.SD, function(x) sum(!is.na(x)))
    ), .SDcols = numeric_vars] %>%
      transpose(keep.names = "Variable") %>%
      .[, lapply(.SD, unlist), by = Variable]
  } else {
    # Grouped summary
    summary_table <- data[, .(
      Mean = lapply(.SD, mean, na.rm = TRUE),
      SD = lapply(.SD, sd, na.rm = TRUE),
      N = lapply(.SD, function(x) sum(!is.na(x)))
    ), by = group_var, .SDcols = numeric_vars] %>%
      melt(id.vars = group_var, variable.factor = FALSE)
  }
  
  return(summary_table)
}

#' Create frequency table
#' @param data Data frame
#' @param var Variable name for frequency table
#' @param sort_by Sort by "frequency" or "name"
#' @return Frequency table
create_frequency_table <- function(data, var, sort_by = "frequency") {
  freq_table <- table(data[[var]])
  freq_df <- data.frame(
    Category = names(freq_table),
    Frequency = as.numeric(freq_table),
    Percentage = round(as.numeric(freq_table) / sum(freq_table) * 100, 2)
  )
  
  if (sort_by == "frequency") {
    freq_df <- freq_df[order(freq_df$Frequency, decreasing = TRUE), ]
  }
  
  return(freq_df)
}

#' Create crosstab table
#' @param data Data frame
#' @param row_var Row variable name
#' @param col_var Column variable name
#' @param value_var Value variable for aggregation (optional)
#' @return Crosstab table
create_crosstab <- function(data, row_var, col_var, value_var = NULL) {
  if (is.null(value_var)) {
    # Frequency crosstab
    crosstab <- table(data[[row_var]], data[[col_var]])
  } else {
    # Aggregated crosstab
    crosstab <- tapply(data[[value_var]], 
                      list(data[[row_var]], data[[col_var]]), 
                      mean, na.rm = TRUE)
  }
  
  return(as.data.frame.matrix(crosstab))
}

#' Create all tables
#' @param data Data frame
#' @param output_dir Output directory
create_tables <- function(data, output_dir) {
  table_dir <- file.path(output_dir, "tables")
  create_dir_if_needed(table_dir)
  
  # Summary table
  summary_table <- create_summary_table(data)
  write.csv(summary_table, 
           file.path(table_dir, paste0("summary_table_", get_timestamp(), ".csv")),
           row.names = FALSE)
  
  # Frequency tables for categorical variables
  categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) || is.character(x))]
  for (var in categorical_vars) {
    freq_table <- create_frequency_table(data, var)
    write.csv(freq_table,
             file.path(table_dir, paste0("freq_", var, "_", get_timestamp(), ".csv")),
             row.names = FALSE)
  }
  
  message("Tables saved to: ", table_dir)
}