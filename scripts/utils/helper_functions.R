# ============================================================================
# Helper Functions
# ============================================================================

#' Load and clean data
#' @param file_path Path to data file
#' @return Cleaned data frame
load_and_clean_data <- function(file_path) {
  # Load data based on file extension
  if (grepl("\\.csv$", file_path)) {
    data <- fread(file_path)
  } else if (grepl("\\.xlsx?$", file_path)) {
    data <- openxlsx::read.xlsx(file_path)
  } else if (grepl("\\.rds$", file_path)) {
    data <- readRDS(file_path)
  } else {
    stop("Unsupported file format")
  }
  
  # Clean data
  data <- clean_missing_values(data)
  data <- fix_data_types(data)
  data <- create_derived_variables(data)
  
  return(data)
}

#' Clean missing values
clean_missing_values <- function(data) {
  # Remove rows with all NAs
  data <- data[rowSums(is.na(data)) < ncol(data), ]
  
  # Handle specific missing value patterns
  # Add custom logic here based on project needs
  
  return(data)
}

#' Fix data types
fix_data_types <- function(data) {
  # Convert character columns that should be factors
  char_cols <- names(data)[sapply(data, is.character)]
  for (col in char_cols) {
    if (length(unique(data[[col]])) < nrow(data) * 0.5) {
      data[[col]] <- as.factor(data[[col]])
    }
  }
  
  return(data)
}

#' Create derived variables
create_derived_variables <- function(data) {
  # Add any derived variables here
  # Example:
  # data$log_value <- log(data$value + 1)
  
  return(data)
}

#' Safe directory creation
#' @param path Directory path to create
create_dir_if_needed <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

#' Get timestamp for file naming
#' @return Formatted timestamp string
get_timestamp <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S")
}