# ============================================================================
# Table Export Functions
# ============================================================================

library(openxlsx)

#' Export tables to Excel with multiple sheets
#' @param tables Named list of data frames
#' @param file_path Output file path
#' @param styling Apply Excel styling
export_to_excel <- function(tables, file_path, styling = TRUE) {
  wb <- createWorkbook()
  
  for (sheet_name in names(tables)) {
    addWorksheet(wb, sheet_name)
    writeData(wb, sheet_name, tables[[sheet_name]])
    
    if (styling) {
      # Apply header style
      header_style <- createStyle(
        fontSize = 11,
        fontColour = "#FFFFFF",
        halign = "center",
        fgFill = "#4472C4",
        border = "TopBottomLeftRight",
        borderColour = "#000000"
      )
      
      addStyle(wb, sheet_name, header_style, 
              rows = 1, cols = 1:ncol(tables[[sheet_name]]), 
              gridExpand = TRUE)
      
      # Auto-fit columns
      setColWidths(wb, sheet_name, 
                  cols = 1:ncol(tables[[sheet_name]]), 
                  widths = "auto")
      
      # Freeze first row
      freezePane(wb, sheet_name, firstRow = TRUE)
    }
  }
  
  saveWorkbook(wb, file_path, overwrite = TRUE)
  message("Excel file saved to: ", file_path)
}

#' Export table to CSV
#' @param data Data frame
#' @param file_path Output file path
export_to_csv <- function(data, file_path) {
  write.csv(data, file_path, row.names = FALSE)
  message("CSV file saved to: ", file_path)
}

#' Export tables to markdown format
#' @param data Data frame
#' @param file_path Output file path
#' @param caption Table caption
export_to_markdown <- function(data, file_path, caption = NULL) {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    warning("knitr package is required for markdown export")
    return(NULL)
  }
  
  md_content <- ""
  
  if (!is.null(caption)) {
    md_content <- paste0(md_content, "### ", caption, "\n\n")
  }
  
  md_content <- paste0(md_content, knitr::kable(data, format = "markdown"))
  
  writeLines(md_content, file_path)
  message("Markdown file saved to: ", file_path)
}

#' Export all tables in multiple formats
#' @param tables Named list of tables
#' @param output_dir Output directory
#' @param formats Vector of formats ("excel", "csv", "markdown")
export_all_tables <- function(tables, output_dir, formats = c("excel", "csv")) {
  create_dir_if_needed(output_dir)
  timestamp <- get_timestamp()
  
  if ("excel" %in% formats) {
    excel_path <- file.path(output_dir, paste0("tables_", timestamp, ".xlsx"))
    export_to_excel(tables, excel_path)
  }
  
  if ("csv" %in% formats) {
    csv_dir <- file.path(output_dir, "csv")
    create_dir_if_needed(csv_dir)
    
    for (table_name in names(tables)) {
      csv_path <- file.path(csv_dir, paste0(table_name, "_", timestamp, ".csv"))
      export_to_csv(tables[[table_name]], csv_path)
    }
  }
  
  if ("markdown" %in% formats) {
    md_dir <- file.path(output_dir, "markdown")
    create_dir_if_needed(md_dir)
    
    for (table_name in names(tables)) {
      md_path <- file.path(md_dir, paste0(table_name, "_", timestamp, ".md"))
      export_to_markdown(tables[[table_name]], md_path, caption = table_name)
    }
  }
}