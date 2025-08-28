# ============================================================================
# DataTable Functions for Interactive Tables
# ============================================================================

library(DT)

#' Create interactive DataTable
#' @param data Data frame
#' @param options List of DataTable options
#' @return DataTable object
create_datatable <- function(data, options = list()) {
  default_options <- list(
    pageLength = 25,
    scrollX = TRUE,
    buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
    dom = 'Bfrtip'
  )
  
  # Merge with user options
  final_options <- modifyList(default_options, options)
  
  dt <- datatable(
    data,
    options = final_options,
    extensions = 'Buttons',
    filter = 'top',
    rownames = FALSE
  )
  
  return(dt)
}

#' Create formatted DataTable with column styling
#' @param data Data frame
#' @param format_columns List of columns to format
#' @return Styled DataTable object
create_formatted_datatable <- function(data, format_columns = NULL) {
  dt <- create_datatable(data)
  
  if (!is.null(format_columns)) {
    # Format numeric columns
    if ("numeric" %in% names(format_columns)) {
      for (col in format_columns$numeric) {
        dt <- dt %>% formatRound(columns = col, digits = 2)
      }
    }
    
    # Format currency columns
    if ("currency" %in% names(format_columns)) {
      for (col in format_columns$currency) {
        dt <- dt %>% formatCurrency(columns = col)
      }
    }
    
    # Format percentage columns
    if ("percentage" %in% names(format_columns)) {
      for (col in format_columns$percentage) {
        dt <- dt %>% formatPercentage(columns = col, digits = 1)
      }
    }
  }
  
  return(dt)
}

#' Create summary DataTable with row grouping
#' @param data Data frame
#' @param group_col Column name for grouping
#' @return Grouped DataTable object
create_grouped_datatable <- function(data, group_col) {
  dt <- datatable(
    data,
    options = list(
      pageLength = 25,
      scrollX = TRUE,
      rowGroup = list(dataSrc = which(names(data) == group_col) - 1)
    ),
    extensions = c('RowGroup', 'Buttons'),
    rownames = FALSE
  )
  
  return(dt)
}