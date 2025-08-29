# ============================================================================
# Helper Functions (data.table & jstable style)
# ============================================================================

library(data.table)
library(magrittr)
library(jstable)
library(openxlsx)

#' Load and clean data (data.table style)
#' @param file_path Path to data file
#' @param check.names Whether to check/fix column names
#' @return data.table object
load_and_clean_data <- function(file_path, check.names = TRUE) {
  # Load data based on file extension
  if (grepl("\\.csv$", file_path)) {
    data <- fread(file_path, check.names = check.names)
  } else if (grepl("\\.xlsx?$", file_path)) {
    data <- openxlsx::read.xlsx(file_path) %>% data.table(check.names = check.names)
  } else if (grepl("\\.rds$", file_path)) {
    data <- readRDS(file_path)
    if (!is.data.table(data)) {
      data <- data.table(data, check.names = check.names)
    }
  } else {
    stop("Unsupported file format")
  }
  
  # Remove completely empty rows
  data <- data[!apply(is.na(data) | data == "", 1, all)]
  
  return(data)
}

#' Prepare data with labels (사용자 스타일)
#' @param data Raw data
#' @param varlist Named list of variable groups
#' @param Event Event variable name for survival (optional)
#' @param Time Time variable name for survival (optional)
#' @return List with data, label, and varlist
prepare_data_labels <- function(data, varlist, Event = NULL, Time = NULL) {
  if (!is.data.table(data)) {
    data <- data.table(data)
  }
  
  # Add survival variables to varlist if provided
  if (!is.null(Event) && !is.null(Time)) {
    varlist$Event <- Event
    varlist$Time <- Time
  }
  
  # Extract all unique variables
  all_vars <- unique(unlist(varlist))
  out <- data[, .SD, .SDcols = all_vars]
  
  # Auto-detect factor variables (6 or fewer unique values)
  factor_vars <- names(out)[sapply(out, function(x) {
    length(unique(x[!is.na(x)])) <= 6
  })]
  
  # Set data types
  out[, (factor_vars) := lapply(.SD, factor), .SDcols = factor_vars]
  conti_vars <- setdiff(names(out), factor_vars)
  out[, (conti_vars) := lapply(.SD, as.numeric), .SDcols = conti_vars]
  
  # Create label data frame
  out.label <- mk.lev(out)
  
  # Auto-label binary variables
  vars01 <- sapply(factor_vars, function(v) {
    identical(levels(out[[v]]), c("0", "1"))
  })
  
  for (v in names(vars01)[vars01 == TRUE]) {
    out.label[variable == v, val_label := c("No", "Yes")]
  }
  
  return(list(
    data = out,
    label = out.label,
    varlist = varlist
  ))
}

#' Fix variable names and labels
#' @param data data.table
#' @param label Label data frame from mk.lev
#' @param name_map Named vector for renaming (old = new)
#' @return Updated label data frame
fix_var_labels <- function(data, label, name_map = NULL) {
  # Rename variables if mapping provided
  if (!is.null(name_map)) {
    for (old_name in names(name_map)) {
      new_name <- name_map[old_name]
      if (old_name %in% names(data)) {
        setnames(data, old_name, new_name)
        label[variable == old_name, variable := new_name]
      }
    }
  }
  
  # Common medical variable labels
  common_labels <- c(
    "Age" = "Age",
    "BMI" = "Body Mass Index",
    "DM" = "Diabetes Mellitus",
    "HTN" = "Hypertension",
    "HbA1c" = "HbA1c (%)",
    "SBP" = "Systolic BP",
    "DBP" = "Diastolic BP"
  )
  
  for (v in names(common_labels)) {
    if (v %in% label$variable) {
      label[variable == v, var_label := common_labels[v]]
    }
  }
  
  return(label)
}

#' Load data from pins board (Zarathu style)
#' @param board_name Board name
#' @param pin_name Pin name
#' @param prefix Board prefix
#' @return data.table object
load_from_pins <- function(board_name, pin_name, prefix = "pins") {
  board <- pins::board_s3(board_name, prefix = prefix)
  data <- pins::pin_read(board, pin_name) %>% data.table(check.names = TRUE)
  return(data)
}

#' Save data to pins board
#' @param data Data to save
#' @param board_name Board name
#' @param pin_name Pin name
#' @param prefix Board prefix
save_to_pins <- function(data, board_name, pin_name, prefix = "pins") {
  board <- pins::board_s3(board_name, prefix = prefix)
  board %>% pins::pin_write(data, name = pin_name, type = "rds")
  message("Data saved to pins: ", pin_name)
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

#' Apply quality control checks
#' @param data data.table
#' @param checks List of check functions
#' @return data.table with QC flags
apply_qc_checks <- function(data, checks = list()) {
  # Example QC check for DXA data
  if ("L1" %in% names(data) && "L2" %in% names(data)) {
    data[, lumbar_qc_bad := as.integer(
      (!is.na(L1 - L2) & abs(L1 - L2) > 1) | 
      (!is.na(L2 - L3) & abs(L2 - L3) > 1) | 
      (!is.na(L3 - L4) & abs(L3 - L4) > 1)
    )]
  }
  
  # Apply custom checks
  for (check_name in names(checks)) {
    data[, (check_name) := checks[[check_name]](data)]
  }
  
  return(data)
}

#' Create categorical variables from continuous
#' @param data data.table
#' @param var Variable name
#' @param cuts Cut points or number of quantiles
#' @param labels Category labels
#' @return data.table with new categorical variable
create_categories <- function(data, var, cuts, labels = NULL) {
  var_cat <- paste0(var, "_cat")
  
  if (length(cuts) == 1) {
    # Use quantiles
    cuts <- quantile(data[[var]], probs = seq(0, 1, 1/cuts), na.rm = TRUE)
  }
  
  data[, (var_cat) := cut(get(var), breaks = cuts, labels = labels, include.lowest = TRUE)]
  
  return(data)
}