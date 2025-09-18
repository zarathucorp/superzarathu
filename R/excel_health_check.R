#' Null coalescing operator
#' @param x First value
#' @param y Default value if x is NULL
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Excel Health Check - Excel Data Quality Assessment
#'
#' Comprehensively checks the data quality of Excel files and generates AI-friendly JSON and markdown reports.
#'
#' Check areas: Structural problems, representation inconsistencies, value errors, missing data, hidden issues
#'
#' 🔹 **Important**: This function never modifies the original Excel files.
#' 🔹 Empty strings ('') are automatically treated as NA following R standards.
#' 🔹 Recommendations are for reference when reading/analyzing data.
#'
#' @param files Vector of Excel file paths to check (if NULL, all Excel files in current directory)
#' @param output_format Output format ("json", "report", "both", default: "both")
#' @param verbose Whether to display progress messages (default: TRUE)
#' @return List of check results (invisible)
#' @export
#' @examples
#' \dontrun{
#' # Check all Excel files in current directory
#' result <- excel_health_check()
#'
#' # Check specific files only
#' result <- excel_health_check(files = c("data1.xlsx", "data2.xlsx"))
#'
#' # Output JSON only
#' result <- excel_health_check(output_format = "json")
#' }
excel_health_check <- function(files = NULL, output_format = "both", verbose = TRUE) {
  # Load and check packages
  check_required_packages()

  # Generate list of files to check
  if (is.null(files)) {
    files <- find_excel_files()
    if (length(files) == 0) {
      stop("No Excel files found in current directory.")
    }
    if (verbose) {
      message("Excel files found: ", length(files), " files")
      message("File list: ", paste(basename(files), collapse = ", "))
    }
  }

  # Basic settings: Convert empty strings to NA for standard R missing value handling
  if (verbose) {
    message("📋 Original file preservation: Original Excel files will not be modified")
    message("📋 Missing value handling: Empty strings ('') converted to NA for standard processing")
  }

  # Check file existence
  missing_files <- files[!file.exists(files)]
  if (length(missing_files) > 0) {
    stop("Cannot find the following files: ", paste(missing_files, collapse = ", "))
  }

  # Start checking
  if (verbose) message("Starting Excel data quality check...")

  start_time <- Sys.time()
  all_results <- list()

  # Check each file
  for (i in seq_along(files)) {
    file_path <- files[i]
    if (verbose) {
      message(sprintf("[%d/%d] Checking %s...", i, length(files), basename(file_path)))
    }

    file_result <- check_excel_file(file_path, verbose = verbose)
    all_results[[basename(file_path)]] <- file_result
  }

  # Organize overall results
  end_time <- Sys.time()

  summary_result <- create_summary(all_results, start_time, end_time)

  # Save results
  if (output_format %in% c("json", "both")) {
    json_output <- generate_json_output(summary_result, all_results)
    if (verbose) {
      message("JSON results saved: ", json_output$json_file)
      message("JSON schema saved: ", json_output$schema_file)
    }
  }

  if (output_format %in% c("report", "both")) {
    report_file <- generate_markdown_report(summary_result, all_results)
    if (verbose) message("Markdown report saved: ", report_file)
  }

  if (verbose) {
    message("✅ Check complete! (Original files were not modified)")
    message("- Check time: ", round(as.numeric(end_time - start_time, units = "secs"), 2), " seconds")
    message("- Files checked: ", length(files), " files")
    message("- Patterns found: ", summary_result$total_issues, " issues")
    message("- Health score: ", summary_result$health_score, "/100")
    message("💡 Recommendations are for reference when reading/analyzing data")
  }

  return(invisible(list(
    summary = summary_result,
    files = all_results
  )))
}

#' Check and load required packages
#' @noRd
check_required_packages <- function() {
  required_packages <- c("openxlsx", "data.table", "jsonlite", "stringdist")

  missing_packages <- setdiff(required_packages, rownames(installed.packages()))
  if (length(missing_packages) > 0) {
    stop(paste("Please install the following packages:", paste(missing_packages, collapse = ", ")))
  }

  # Load packages
  for (pkg in required_packages) {
    suppressPackageStartupMessages(require(pkg, character.only = TRUE, quietly = TRUE))
  }
}

#' Find Excel files in current directory
#' @noRd
find_excel_files <- function() {
  excel_extensions <- c("*.xlsx", "*.xls", "*.xlsm")
  files <- c()

  for (ext in excel_extensions) {
    files <- c(files, Sys.glob(ext))
  }

  return(files)
}

#' Check individual Excel file
#' @param file_path Excel file path
#' @param verbose Whether to display progress messages
#' @noRd
check_excel_file <- function(file_path, verbose = FALSE) {
  tryCatch({
    # Get file information
    file_info <- file.info(file_path)

    # Open workbook
    wb <- openxlsx::loadWorkbook(file_path)
    sheet_names <- openxlsx::getSheetNames(file_path)

    if (verbose) message("  Number of sheets: ", length(sheet_names))

    # Check each sheet
    sheets_results <- list()

    for (sheet_name in sheet_names) {
      if (verbose) message("    Checking sheet: ", sheet_name)

      sheet_result <- check_excel_sheet(file_path, sheet_name, wb)
      sheets_results[[sheet_name]] <- sheet_result
    }

    return(list(
      file_name = basename(file_path),
      file_path = file_path,
      file_size = file_info$size,
      modified_time = file_info$mtime,
      sheets = sheets_results
    ))

  }, error = function(e) {
    return(list(
      file_name = basename(file_path),
      file_path = file_path,
      error = paste("File reading error:", e$message),
      sheets = list()
    ))
  })
}

#' Check individual sheet
#' @param file_path Excel file path
#' @param sheet_name Sheet name
#' @param wb Workbook object
#' @noRd
check_excel_sheet <- function(file_path, sheet_name, wb) {
  tryCatch({
    # Read sheet data
    data <- openxlsx::read.xlsx(file_path, sheet = sheet_name,
                                colNames = FALSE, skipEmptyRows = FALSE,
                                skipEmptyCols = FALSE)

    # Convert empty strings to NA (R standard missing value handling)
    data[data == ""] <- NA

    # Sheet information
    sheet_info <- list(
      sheet_name = sheet_name,
      dimensions = dim(data),
      issues = list()
    )

    # Perform various checks
    issues <- list()

    # 1. Structural problem checks
    check_functions <- list(
      function() check_merged_cells(wb, sheet_name),
      function() check_data_start_position(data),
      function() check_multiple_values_in_cell(data),
      function() check_pivot_format(data),
      function() check_summary_rows(data),
      # 2. Representation inconsistency checks
      function() check_name_inconsistency(data),
      function() check_date_format_inconsistency(data),
      function() check_unit_inconsistency(data),
      function() check_boolean_inconsistency(data),
      function() check_category_inconsistency(data),
      # 3. Value error checks
      function() check_whitespace_issues(data),
      function() check_text_formatted_numbers(data),
      function() check_special_characters(data),
      function() check_duplicate_rows(data),
      # 4. Missing data checks
      function() check_missing_values(data),
      function() check_placeholder_usage(data),
      function() check_implicit_missing(data),
      # 5. Hidden problem checks
      function() check_formula_errors(data),
      function() check_encoding_issues(data)
    )

    # Execute each check function and add only non-NULL results
    for (check_func in check_functions) {
      result <- tryCatch(check_func(), error = function(e) NULL)
      if (!is.null(result)) {
        issues <- append(issues, list(result))
      }
    }

    sheet_info$issues <- issues
    return(sheet_info)

  }, error = function(e) {
    return(list(
      sheet_name = sheet_name,
      error = paste("Sheet reading error:", e$message),
      issues = list()
    ))
  })
}

# ==============================================
# Structural problem check functions
# ==============================================

#' Check merged cells
#' @param wb Workbook object
#' @param sheet_name Sheet name
#' @noRd
check_merged_cells <- function(wb, sheet_name) {
  tryCatch({
    merged_cells <- wb$worksheets[[sheet_name]]$mergedCells

    if (length(merged_cells) > 0) {
      return(list(
        type = "merged_cells",
        severity = "high",
        count = length(merged_cells),
        locations = merged_cells,
        description = "Merged cells found",
        recommendation = "Consider unmerging cells and normalizing data for analysis"
      ))
    }
    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

#' Check data not starting from A1
#' @param data Sheet data
#' @noRd
check_data_start_position <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Find first non-empty cell in first row and column
  first_row <- which(apply(data, 1, function(x) any(!is.na(x))))[1]
  first_col <- which(apply(data, 2, function(x) any(!is.na(x))))[1]

  if (is.na(first_row) || is.na(first_col)) return(NULL)

  if (first_row > 1 || first_col > 1) {
    return(list(
      type = "data_start_position",
      severity = "medium",
      count = 1,
      locations = paste0(LETTERS[first_col], first_row),
      description = sprintf("Data starts at %s%d instead of A1",
                           LETTERS[first_col], first_row),
      recommendation = "Consider adjusting start position with range or skip options when reading data"
    ))
  }
  return(NULL)
}

#' Check multiple values in one cell
#' @param data Sheet data
#' @noRd
check_multiple_values_in_cell <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Find separator patterns (/, |, ;, , etc.)
  separators <- c("/", "\\|", ";", ",", "・")
  multi_value_cells <- c()

  for (i in 1:nrow(data)) {
    for (j in 1:ncol(data)) {
      cell_value <- as.character(data[i, j])
      if (is.na(cell_value)) next

      # Cases with 2 or more separators (excluding simple addresses or dates)
      separator_count <- sum(sapply(separators, function(sep) {
        length(gregexpr(sep, cell_value)[[1]]) - (gregexpr(sep, cell_value)[[1]][1] == -1)
      }))

      if (separator_count >= 2) {
        multi_value_cells <- c(multi_value_cells, paste0(LETTERS[j], i))
      }
    }
  }

  if (length(multi_value_cells) > 0) {
    return(list(
      type = "multiple_values_in_cell",
      severity = "medium",
      count = length(multi_value_cells),
      locations = head(multi_value_cells, 10), # Show maximum 10 cells
      description = "Multiple values found in single cells",
      recommendation = "Multiple values in one cell detected. Consider separating or using regex during analysis"
    ))
  }
  return(NULL)
}

#' Check pivot table format
#' @param data Sheet data
#' @noRd
check_pivot_format <- function(data) {
  if (nrow(data) < 3 || ncol(data) < 3) return(NULL)

  # If first row and column have categorical data,
  # and the rest are numbers, judge as pivot format
  first_row <- data[1, ]
  first_col <- data[, 1]

  # Case with much text in first row
  text_in_first_row <- sum(!is.na(first_row) & !suppressWarnings(is.na(as.numeric(first_row))))

  # Case with many numbers in remaining data
  numeric_data <- data[2:nrow(data), 2:ncol(data)]
  numeric_cells <- sum(!is.na(numeric_data) & !suppressWarnings(is.na(as.numeric(as.matrix(numeric_data)))))
  total_cells <- sum(!is.na(numeric_data))

  if (text_in_first_row >= 2 && total_cells > 0 && numeric_cells / total_cells > 0.7) {
    return(list(
      type = "pivot_format",
      severity = "high",
      count = 1,
      locations = "Entire sheet",
      description = "Data appears to be in pivot table format",
      recommendation = "Pivot format data detected. Consider converting to original format (melt/pivot_longer) for analysis"
    ))
  }
  return(NULL)
}

#' 불필요한 요약 행/열 검사
#' @param data 시트 데이터
#' @noRd
check_summary_rows <- function(data) {
  if (nrow(data) < 2 || ncol(data) < 2) return(NULL)

  summary_indicators <- c("합계", "소계", "계", "총계", "평균", "합", "sum", "total", "average", "subtotal")
  summary_locations <- c()

  # Check rows
  for (i in 1:nrow(data)) {
    row_text <- paste(tolower(as.character(data[i, ])), collapse = " ")
    if (any(sapply(summary_indicators, function(x) grepl(x, row_text, ignore.case = TRUE)))) {
      summary_locations <- c(summary_locations, paste0("Row", i))
    }
  }

  # Check columns
  for (j in 1:ncol(data)) {
    col_text <- paste(tolower(as.character(data[, j])), collapse = " ")
    if (any(sapply(summary_indicators, function(x) grepl(x, col_text, ignore.case = TRUE)))) {
      summary_locations <- c(summary_locations, paste0("Col", LETTERS[j]))
    }
  }

  if (length(summary_locations) > 0) {
    return(list(
      type = "summary_rows",
      severity = "medium",
      count = length(summary_locations),
      locations = summary_locations,
      description = "Summary rows/columns are included within the data",
      recommendation = "Summary rows/columns detected. Consider excluding these rows/columns when reading data"
    ))
  }
  return(NULL)
}

# ==============================================
# Representation inconsistency check functions
# ==============================================

#' Check name inconsistency
#' @param data Sheet data
#' @noRd
check_name_inconsistency <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Find text columns
  text_columns <- c()
  for (j in 1:ncol(data)) {
    col_data <- data[, j]
    text_ratio <- sum(!is.na(col_data) & suppressWarnings(is.na(as.numeric(col_data)))) / sum(!is.na(col_data))
    if (text_ratio > 0.5) {
      text_columns <- c(text_columns, j)
    }
  }

  inconsistencies <- list()

  for (j in text_columns) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) < 2) next

    # Find similar strings (using Levenshtein distance)
    unique_values <- unique(col_data)

    for (i in 1:(length(unique_values) - 1)) {
      for (k in (i + 1):length(unique_values)) {
        val1 <- unique_values[i]
        val2 <- unique_values[k]

        # Skip if length is too different
        if (abs(nchar(val1) - nchar(val2)) > 3) next

        # Calculate Levenshtein distance
        distance <- stringdist::stringdist(val1, val2, method = "lv")
        similarity <- 1 - distance / max(nchar(val1), nchar(val2))

        if (similarity > 0.7 && similarity < 1) {
          inconsistencies <- append(inconsistencies, list(list(
            column = LETTERS[j],
            values = c(val1, val2),
            similarity = round(similarity, 3)
          )))
        }
      }
    }
  }

  if (length(inconsistencies) > 0) {
    return(list(
      type = "name_inconsistency",
      severity = "high",
      count = length(inconsistencies),
      details = head(inconsistencies, 5), # Show maximum 5 items
      description = "Similar but different names found",
      recommendation = "Name inconsistency for same entities detected. Consider unified processing (recode, case_when) during analysis"
    ))
  }
  return(NULL)
}

#' Check date format inconsistency
#' @param data Sheet data
#' @noRd
check_date_format_inconsistency <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  date_patterns <- list(
    "yyyy-mm-dd" = "\\d{4}-\\d{1,2}-\\d{1,2}",
    "yyyy/mm/dd" = "\\d{4}/\\d{1,2}/\\d{1,2}",
    "yy.mm.dd" = "\\d{2}\\.\\d{1,2}\\.\\d{1,2}",
    "dd/mm/yyyy" = "\\d{1,2}/\\d{1,2}/\\d{4}",
    "mm-dd-yyyy" = "\\d{1,2}-\\d{1,2}-\\d{4}"
  )

  inconsistent_columns <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) < 2) next

    # Date pattern matching
    pattern_matches <- list()
    for (pattern_name in names(date_patterns)) {
      pattern <- date_patterns[[pattern_name]]
      matches <- sum(grepl(pattern, col_data))
      if (matches > 0) {
        pattern_matches[[pattern_name]] <- matches
      }
    }

    # Inconsistency if 2 or more patterns found
    if (length(pattern_matches) > 1) {
      inconsistent_columns[[LETTERS[j]]] <- pattern_matches
    }
  }

  if (length(inconsistent_columns) > 0) {
    return(list(
      type = "date_format_inconsistency",
      severity = "medium",
      count = length(inconsistent_columns),
      columns = names(inconsistent_columns),
      details = inconsistent_columns,
      description = "Date formats are inconsistent",
      recommendation = "Date format inconsistency detected. Consider applying appropriate conversion (as.Date) for each format when reading"
    ))
  }
  return(NULL)
}

#' 단위 불일치 검사
#' @param data 시트 데이터
#' @noRd
check_unit_inconsistency <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  unit_groups <- list(
    "currency" = c("원", "천원", "만원", "억원", "won", "krw"),
    "weight" = c("g", "kg", "gram", "kilogram", "그램", "킬로그램"),
    "length" = c("mm", "cm", "m", "km", "미터", "센티미터"),
    "percentage" = c("%", "퍼센트", "percent")
  )

  inconsistent_columns <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) < 2) next

    for (group_name in names(unit_groups)) {
      units <- unit_groups[[group_name]]
      found_units <- c()

      for (unit in units) {
        if (any(grepl(unit, col_data, ignore.case = TRUE))) {
          found_units <- c(found_units, unit)
        }
      }

      if (length(found_units) > 1) {
        inconsistent_columns[[paste0(LETTERS[j], "_", group_name)]] <- found_units
      }
    }
  }

  if (length(inconsistent_columns) > 0) {
    return(list(
      type = "unit_inconsistency",
      severity = "medium",
      count = length(inconsistent_columns),
      details = inconsistent_columns,
      description = "Unit notations are inconsistent",
      recommendation = "Unit inconsistency detected. Consider unit conversion or group-wise analysis during analysis"
    ))
  }
  return(NULL)
}

#' Check boolean expression inconsistency
#' @param data Sheet data
#' @noRd
check_boolean_inconsistency <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  boolean_patterns <- list(
    "Y/N" = c("y", "n", "yes", "no"),
    "T/F" = c("t", "f", "true", "false", "참", "거짓"),
    "1/0" = c("1", "0"),
    "한글" = c("예", "아니오", "있음", "없음", "완료", "미완료")
  )

  inconsistent_columns <- list()

  for (j in 1:ncol(data)) {
    col_data <- tolower(as.character(data[, j]))
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) < 2) next

    found_patterns <- c()
    for (pattern_name in names(boolean_patterns)) {
      pattern_values <- boolean_patterns[[pattern_name]]
      if (any(col_data %in% pattern_values)) {
        found_patterns <- c(found_patterns, pattern_name)
      }
    }

    if (length(found_patterns) > 1) {
      inconsistent_columns[[LETTERS[j]]] <- found_patterns
    }
  }

  if (length(inconsistent_columns) > 0) {
    return(list(
      type = "boolean_inconsistency",
      severity = "medium",
      count = length(inconsistent_columns),
      columns = names(inconsistent_columns),
      details = inconsistent_columns,
      description = "Boolean expressions are inconsistent",
      recommendation = "Boolean expression inconsistency detected. Consider converting to logical type (TRUE/FALSE) when reading"
    ))
  }
  return(NULL)
}

#' Check category classification inconsistency
#' @param data Sheet data
#' @noRd
check_category_inconsistency <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  inconsistent_categories <- list()

  # Find category inconsistency in text columns
  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) < 3) next

    unique_values <- unique(col_data)
    if (length(unique_values) < 3) next

    # Find spacing inconsistency
    spacing_issues <- c()
    for (val in unique_values) {
      # Values with spaces
      if (grepl(" ", val)) {
        no_space_version <- gsub(" ", "", val)
        if (no_space_version %in% unique_values) {
          spacing_issues <- c(spacing_issues, paste(val, "vs", no_space_version))
        }
      }
    }

    if (length(spacing_issues) > 0) {
      inconsistent_categories[[LETTERS[j]]] <- spacing_issues
    }
  }

  if (length(inconsistent_categories) > 0) {
    return(list(
      type = "category_inconsistency",
      severity = "medium",
      count = length(inconsistent_categories),
      columns = names(inconsistent_categories),
      details = inconsistent_categories,
      description = "Category classification inconsistencies found (mainly spacing)",
      recommendation = "Category notation inconsistency (spacing, etc.) detected. Consider standardization during analysis"
    ))
  }
  return(NULL)
}

# ==============================================
# Value error check functions
# ==============================================


#' Check unnecessary whitespace
#' @param data Sheet data
#' @noRd
check_whitespace_issues <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  whitespace_issues <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) == 0) next

    # Leading/trailing spaces
    leading_trailing <- sum(col_data != trimws(col_data))

    # Multiple consecutive spaces
    multiple_spaces <- sum(grepl("  +", col_data))

    # Tab characters
    tab_chars <- sum(grepl("\\t", col_data))

    issues <- list()
    if (leading_trailing > 0) issues$leading_trailing <- leading_trailing
    if (multiple_spaces > 0) issues$multiple_spaces <- multiple_spaces
    if (tab_chars > 0) issues$tab_chars <- tab_chars

    if (length(issues) > 0) {
      whitespace_issues[[LETTERS[j]]] <- issues
    }
  }

  if (length(whitespace_issues) > 0) {
    total_issues <- sum(sapply(whitespace_issues, function(x) sum(unlist(x))))
    return(list(
      type = "whitespace_issues",
      severity = "low",
      count = total_issues,
      columns = names(whitespace_issues),
      details = whitespace_issues,
      description = "Unnecessary whitespace or tab characters found",
      recommendation = "Unnecessary whitespace detected. Consider applying trimws() function after reading"
    ))
  }
  return(NULL)
}

#' Check numbers stored as text
#' @param data Sheet data
#' @noRd
check_text_formatted_numbers <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  text_number_columns <- list()

  for (j in 1:ncol(data)) {
    col_data <- data[, j]
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) == 0) next

    # String values that can be converted to numbers
    char_data <- as.character(col_data)
    numeric_convertible <- suppressWarnings(!is.na(as.numeric(char_data)))

    # Cases with thousand separators
    comma_numbers <- grepl("^[0-9,]+$", char_data)

    # Cases with apostrophe before numbers
    quote_numbers <- grepl("^'[0-9]+", char_data)

    issues <- list()
    if (sum(comma_numbers) > 0) issues$comma_separated <- sum(comma_numbers)
    if (sum(quote_numbers) > 0) issues$quoted_numbers <- sum(quote_numbers)
    if (sum(numeric_convertible) > length(col_data) * 0.5 &&
        !is.numeric(col_data)) issues$text_numbers <- sum(numeric_convertible)

    if (length(issues) > 0) {
      text_number_columns[[LETTERS[j]]] <- issues
    }
  }

  if (length(text_number_columns) > 0) {
    total_issues <- sum(sapply(text_number_columns, function(x) sum(unlist(x))))
    return(list(
      type = "text_formatted_numbers",
      severity = "medium",
      count = total_issues,
      columns = names(text_number_columns),
      details = text_number_columns,
      description = "Numbers are stored in text format",
      recommendation = "Text-format numbers detected. Consider type conversion (as.numeric) and thousand separator handling when reading"
    ))
  }
  return(NULL)
}

#' Check special characters
#' @param data Sheet data
#' @noRd
check_special_characters <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Potentially problematic special characters
  problematic_chars <- c("\\*", "#", "\\n", "\\r", "\\t", "[^\\x20-\\x7E가-힣]")
  char_names <- c("Asterisk(*)", "Hash(#)", "Newline", "Carriage Return", "Tab", "Special Characters")

  special_char_issues <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) == 0) next

    issues <- list()
    for (i in seq_along(problematic_chars)) {
      char_pattern <- problematic_chars[i]
      char_name <- char_names[i]

      matches <- sum(grepl(char_pattern, col_data))
      if (matches > 0) {
        issues[[char_name]] <- matches
      }
    }

    if (length(issues) > 0) {
      special_char_issues[[LETTERS[j]]] <- issues
    }
  }

  if (length(special_char_issues) > 0) {
    total_issues <- sum(sapply(special_char_issues, function(x) sum(unlist(x))))
    return(list(
      type = "special_characters",
      severity = "low",
      count = total_issues,
      columns = names(special_char_issues),
      details = special_char_issues,
      description = "Potentially problematic special characters found",
      recommendation = "Special characters detected. Consider handling with regex or checking encoding when reading"
    ))
  }
  return(NULL)
}

#' Check duplicate rows
#' @param data Sheet data
#' @noRd
check_duplicate_rows <- function(data) {
  if (nrow(data) < 2) return(NULL)

  # Find completely identical rows
  data_char <- data.frame(lapply(data, as.character), stringsAsFactors = FALSE)

  # Exclude empty rows
  non_empty_rows <- apply(data_char, 1, function(x) !all(is.na(x)))
  data_char <- data_char[non_empty_rows, , drop = FALSE]

  if (nrow(data_char) < 2) return(NULL)

  # Check for duplicates
  duplicated_rows <- duplicated(data_char) | duplicated(data_char, fromLast = TRUE)
  duplicate_count <- sum(duplicated_rows)

  if (duplicate_count > 0) {
    # Indices of duplicated rows
    dup_indices <- which(duplicated_rows)

    return(list(
      type = "duplicate_rows",
      severity = "medium",
      count = duplicate_count,
      duplicate_row_indices = head(dup_indices, 10), # Show maximum 10 indices
      description = sprintf("%d completely identical rows found", duplicate_count),
      recommendation = "Duplicate rows detected. Consider using unique() or distinct() during analysis"
    ))
  }
  return(NULL)
}

# ==============================================
# Missing data check functions
# ==============================================

#' Check empty cells
#' @param data Sheet data
#' @noRd
check_missing_values <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  total_cells <- nrow(data) * ncol(data)
  missing_cells <- sum(is.na(data))
  missing_percentage <- round(missing_cells / total_cells * 100, 2)

  column_missing <- sapply(1:ncol(data), function(j) {
    col_missing <- sum(is.na(data[, j]))
    round(col_missing / nrow(data) * 100, 2)
  })

  high_missing_cols <- which(column_missing > 50)

  if (missing_percentage > 10) {
    result <- list(
      type = "missing_values",
      severity = if (missing_percentage > 30) "high" else "medium",
      count = missing_cells,
      total_percentage = missing_percentage,
      description = sprintf("%.2f%% of all cells are empty", missing_percentage),
      recommendation = "High proportion of NA values detected. Consider using complete.cases() or na.omit() during analysis"
    )

    if (length(high_missing_cols) > 0) {
      result$high_missing_columns <- paste0(LETTERS[high_missing_cols], " (",
                                           column_missing[high_missing_cols], "%)")
    }

    return(result)
  }
  return(NULL)
}

#' Check placeholder usage
#' @param data Sheet data
#' @noRd
check_placeholder_usage <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  placeholders <- c("없음", "해당없음", "-", ".", "null", "NULL", "빈값", "N/A", "n/a")
  placeholder_found <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])

    for (placeholder in placeholders) {
      count <- sum(col_data == placeholder, na.rm = TRUE)
      if (count > 0) {
        if (is.null(placeholder_found[[LETTERS[j]]])) {
          placeholder_found[[LETTERS[j]]] <- list()
        }
        placeholder_found[[LETTERS[j]]][[placeholder]] <- count
      }
    }
  }

  if (length(placeholder_found) > 0) {
    total_count <- sum(sapply(placeholder_found, function(x) sum(unlist(x))))
    return(list(
      type = "placeholder_usage",
      severity = "low",
      count = total_count,
      columns = names(placeholder_found),
      details = placeholder_found,
      description = "Various placeholders are being used",
      recommendation = "Various NA expressions detected. Can be handled uniformly with na.strings option when reading"
    ))
  }
  return(NULL)
}

#' Check implicit missing data
#' @param data Sheet data
#' @noRd
check_implicit_missing <- function(data) {
  if (nrow(data) < 3 || ncol(data) < 2) return(NULL)

  # Find patterns similar to merged cells (group headers with empty rest)
  implicit_missing <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])

    # Pattern where values come after consecutive empty cells
    for (i in 2:(nrow(data) - 1)) {
      if (!is.na(col_data[i]) && is.na(col_data[i + 1])) {

        # Check if the next few rows are empty
        empty_count <- 0
        for (k in (i + 1):min(i + 5, nrow(data))) {
          if (is.na(col_data[k])) {
            empty_count <- empty_count + 1
          } else {
            break
          }
        }

        if (empty_count >= 2) {
          implicit_missing[[paste0(LETTERS[j], i)]] <- empty_count
        }
      }
    }
  }

  if (length(implicit_missing) > 0) {
    return(list(
      type = "implicit_missing",
      severity = "medium",
      count = length(implicit_missing),
      locations = names(implicit_missing),
      details = implicit_missing,
      description = "Implicit missing data (empty cells after group headers) found",
      recommendation = "Implicit NA pattern due to group header structure detected. Consider using fill() function during analysis"
    ))
  }
  return(NULL)
}

# ==============================================
# Hidden problem check functions
# ==============================================

#' Check formula error values
#' @param data Sheet data
#' @noRd
check_formula_errors <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  error_patterns <- c("#N/A", "#VALUE!", "#REF!", "#DIV/0!", "#NUM!", "#NAME?", "#NULL!")
  error_found <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])

    for (error_pattern in error_patterns) {
      count <- sum(grepl(error_pattern, col_data, fixed = TRUE), na.rm = TRUE)
      if (count > 0) {
        if (is.null(error_found[[LETTERS[j]]])) {
          error_found[[LETTERS[j]]] <- list()
        }
        error_found[[LETTERS[j]]][[error_pattern]] <- count
      }
    }
  }

  if (length(error_found) > 0) {
    total_count <- sum(sapply(error_found, function(x) sum(unlist(x))))
    return(list(
      type = "formula_errors",
      severity = "high",
      count = total_count,
      columns = names(error_found),
      details = error_found,
      description = "Formula error values found",
      recommendation = "Formula error values detected. Need to decide how to handle these values when reading"
    ))
  }
  return(NULL)
}

#' Check encoding problems
#' @param data Sheet data
#' @noRd
check_encoding_issues <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Strange character patterns due to encoding problems
  encoding_patterns <- c("Ã", "â€", "Â", "Ç", "¿", "¾", "½")
  encoding_issues <- list()

  for (j in 1:ncol(data)) {
    col_data <- as.character(data[, j])
    col_data <- col_data[!is.na(col_data)]

    if (length(col_data) == 0) next

    issue_count <- 0
    for (pattern in encoding_patterns) {
      issue_count <- issue_count + sum(grepl(pattern, col_data))
    }

    if (issue_count > 0) {
      encoding_issues[[LETTERS[j]]] <- issue_count
    }
  }

  if (length(encoding_issues) > 0) {
    total_count <- sum(unlist(encoding_issues))
    return(list(
      type = "encoding_issues",
      severity = "medium",
      count = total_count,
      columns = names(encoding_issues),
      details = encoding_issues,
      description = "Strange characters due to encoding problems found",
      recommendation = "Characters suspected of encoding problems detected. Need to check encoding option when reading"
    ))
  }
  return(NULL)
}

# ==============================================
# Result generation functions
# ==============================================

#' Generate overall result summary
#' @param all_results All file results
#' @param start_time Start time
#' @param end_time End time
#' @noRd
create_summary <- function(all_results, start_time, end_time) {
  total_files <- length(all_results)
  total_issues <- 0
  issue_types <- list()

  for (file_result in all_results) {
    if (!is.null(file_result$sheets)) {
      for (sheet_result in file_result$sheets) {
        if (!is.null(sheet_result$issues)) {
          total_issues <- total_issues + length(sheet_result$issues)

          for (issue in sheet_result$issues) {
            if (is.list(issue) && !is.null(issue$type)) {
              issue_type <- issue$type
              if (is.null(issue_types[[issue_type]])) {
                issue_types[[issue_type]] <- 0
              }
              issue_types[[issue_type]] <- issue_types[[issue_type]] + 1
            }
          }
        }
      }
    }
  }

  # Calculate health score (out of 100)
  health_score <- calculate_health_score(total_issues, total_files)

  list(
    total_files = total_files,
    total_issues = total_issues,
    issue_types = issue_types,
    health_score = health_score,
    analysis_time = as.numeric(end_time - start_time, units = "secs"),
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}

#' Calculate health score
#' @param total_issues Total number of issues
#' @param total_files Total number of files
#' @noRd
calculate_health_score <- function(total_issues, total_files) {
  if (total_files == 0) return(0)

  # Average issues per file
  avg_issues_per_file <- total_issues / total_files

  # Score calculation (more issues = lower score)
  base_score <- 100
  penalty <- min(avg_issues_per_file * 2, 80) # Maximum 80 point deduction

  score <- max(base_score - penalty, 0)
  return(round(score, 1))
}

#' JSON Schema 생성
#' @noRd
generate_json_schema <- function() {
  schema <- list(
    `$schema` = "http://json-schema.org/draft-07/schema#",
    title = "Excel Health Check Results",
    description = "JSON schema for Excel data quality check results. Structure definition for AI to understand and utilize results.",
    type = "object",
    properties = list(
      summary = list(
        type = "object",
        description = "Overall check results summary",
        properties = list(
          total_files = list(
            type = "integer",
            description = "Total number of files checked"
          ),
          total_issues = list(
            type = "integer",
            description = "Total number of issues found"
          ),
          issue_types = list(
            type = "object",
            description = "Number of occurrences by issue type",
            additionalProperties = list(type = "integer")
          ),
          health_score = list(
            type = "number",
            minimum = 0,
            maximum = 100,
            description = "Data quality health score (0-100 points)"
          ),
          analysis_time = list(
            type = "number",
            description = "Analysis time required (seconds)"
          ),
          timestamp = list(
            type = "string",
            description = "Check execution time (YYYY-MM-DD HH:MM:SS)"
          )
        ),
        required = list("total_files", "total_issues", "health_score", "timestamp")
      ),
      files = list(
        type = "object",
        description = "Detailed check results by file",
        additionalProperties = list(
          type = "object",
          properties = list(
            file_name = list(
              type = "string",
              description = "File name"
            ),
            file_path = list(
              type = "string",
              description = "File path"
            ),
            file_size = list(
              type = "integer",
              description = "File size (bytes)"
            ),
            modified_time = list(
              type = "string",
              description = "File modification time"
            ),
            error = list(
              type = "string",
              description = "File reading error message (if any)"
            ),
            sheets = list(
              type = "object",
              description = "Check results by sheet",
              additionalProperties = list(
                type = "object",
                properties = list(
                  sheet_name = list(
                    type = "string",
                    description = "Sheet name"
                  ),
                  dimensions = list(
                    type = "array",
                    items = list(type = "integer"),
                    minItems = 2,
                    maxItems = 2,
                    description = "Sheet size [rows, columns]"
                  ),
                  error = list(
                    type = "string",
                    description = "Sheet reading error message (if any)"
                  ),
                  issues = list(
                    type = "array",
                    description = "Data quality issues found",
                    items = list(
                      type = "object",
                      properties = list(
                        type = list(
                          type = "string",
                          enum = list(
                            "merged_cells", "data_start_position", "multiple_values_in_cell",
                            "pivot_format", "summary_rows", "name_inconsistency",
                            "date_format_inconsistency", "unit_inconsistency",
                            "boolean_inconsistency", "category_inconsistency",
                            "whitespace_issues", "text_formatted_numbers",
                            "special_characters", "duplicate_rows", "missing_values",
                            "placeholder_usage", "implicit_missing", "formula_errors",
                            "encoding_issues"
                          ),
                          description = "Issue type"
                        ),
                        severity = list(
                          type = "string",
                          enum = list("low", "medium", "high"),
                          description = "Severity level"
                        ),
                        count = list(
                          type = "integer",
                          description = "Number of occurrences of this issue"
                        ),
                        description = list(
                          type = "string",
                          description = "Description of the issue"
                        ),
                        recommendation = list(
                          type = "string",
                          description = "Recommended solution"
                        ),
                        locations = list(
                          type = "array",
                          items = list(type = "string"),
                          description = "Locations where the issue was found (cell addresses, etc.)"
                        ),
                        details = list(
                          description = "Detailed information about the issue (structure varies by issue type)"
                        )
                      ),
                      required = list("type", "severity", "count", "description", "recommendation")
                    )
                  )
                ),
                required = list("sheet_name", "issues")
              )
            )
          ),
          required = list("file_name", "file_path")
        )
      )
    ),
    required = list("summary", "files")
  )

  return(schema)
}

#' Generate JSON output
#' @param summary_result Summary result
#' @param all_results All file results
#' @noRd
generate_json_output <- function(summary_result, all_results) {
  output_data <- list(
    summary = summary_result,
    files = all_results
  )

  # Generate timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # Generate JSON result file
  json_file <- paste0("sz_excel_results_", timestamp, ".json")
  jsonlite::write_json(output_data, json_file, pretty = TRUE, auto_unbox = TRUE)

  # Generate JSON Schema file (fixed filename)
  schema <- generate_json_schema()
  schema_file <- "sz_excel_schema.json"
  jsonlite::write_json(schema, schema_file, pretty = TRUE, auto_unbox = TRUE)

  return(list(json_file = json_file, schema_file = schema_file))
}

#' Generate markdown report
#' @param summary_result Summary result
#' @param all_results All file results
#' @noRd
generate_markdown_report <- function(summary_result, all_results) {
  # Generate timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  report_lines <- c()

  # Title
  report_lines <- c(report_lines, "# Excel Data Quality Check Report")
  report_lines <- c(report_lines, "")

  # Summary
  report_lines <- c(report_lines, "## 📊 Check Summary")
  report_lines <- c(report_lines, "")
  report_lines <- c(report_lines, paste("- **Check Time:** ", summary_result$timestamp))
  report_lines <- c(report_lines, paste("- **Files Checked:** ", summary_result$total_files, " files"))
  report_lines <- c(report_lines, paste("- **Total Issues:** ", summary_result$total_issues, " issues"))
  report_lines <- c(report_lines, paste("- **Health Score:** ", summary_result$health_score, "/100"))
  report_lines <- c(report_lines, paste("- **Analysis Time:** ", round(summary_result$analysis_time, 2), " seconds"))
  report_lines <- c(report_lines, "")

  # Health score interpretation
  health_score <- summary_result$health_score
  if (health_score >= 90) {
    health_status <- "🟢 **Excellent** - Data quality is very good"
  } else if (health_score >= 70) {
    health_status <- "🟡 **Good** - Some improvements needed"
  } else if (health_score >= 50) {
    health_status <- "🟠 **Caution** - Significant improvements needed"
  } else {
    health_status <- "🔴 **Critical** - Comprehensive data cleanup required"
  }
  report_lines <- c(report_lines, paste("**Health Status:** ", health_status))
  report_lines <- c(report_lines, "")

  # Issue Type Statistics
  if (length(summary_result$issue_types) > 0) {
    report_lines <- c(report_lines, "## 📈 Issue Type Statistics")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "| Issue Type | Count | Description |")
    report_lines <- c(report_lines, "|------------|-------|-------------|")

    issue_descriptions <- list(
      "merged_cells" = "Merged cells",
      "data_start_position" = "Data starting at non-A1 position",
      "multiple_values_in_cell" = "Multiple values in one cell",
      "pivot_format" = "Pivot table format",
      "summary_rows" = "Unnecessary summary rows/columns",
      "name_inconsistency" = "Name inconsistency",
      "date_format_inconsistency" = "Date format inconsistency",
      "unit_inconsistency" = "Unit inconsistency",
      "boolean_inconsistency" = "Boolean value inconsistency",
      "category_inconsistency" = "Category classification inconsistency",
      "whitespace_issues" = "Unnecessary whitespace",
      "text_formatted_numbers" = "Numbers stored as text",
      "special_characters" = "Special characters",
      "duplicate_rows" = "Duplicate rows",
      "missing_values" = "Empty cells",
      "placeholder_usage" = "Placeholder usage",
      "implicit_missing" = "Implicit missing values",
      "formula_errors" = "Formula errors",
      "encoding_issues" = "Encoding issues"
    )

    for (issue_type in names(summary_result$issue_types)) {
      count <- summary_result$issue_types[[issue_type]]
      description <- issue_descriptions[[issue_type]] %||% issue_type
      report_lines <- c(report_lines, paste("|", description, "|", count, "| - |"))
    }
    report_lines <- c(report_lines, "")
  }

  # Detailed Results by File
  report_lines <- c(report_lines, "## 📁 Detailed Analysis by File")
  report_lines <- c(report_lines, "")

  for (file_name in names(all_results)) {
    file_result <- all_results[[file_name]]

    report_lines <- c(report_lines, paste("###", file_name))
    report_lines <- c(report_lines, "")

    if (!is.null(file_result$error)) {
      report_lines <- c(report_lines, paste("❌ **Error:** ", file_result$error))
      report_lines <- c(report_lines, "")
      next
    }

    if (!is.null(file_result$file_size)) {
      file_size_mb <- round(file_result$file_size / 1024 / 1024, 2)
      report_lines <- c(report_lines, paste("- **File Size:** ", file_size_mb, "MB"))
    }

    if (!is.null(file_result$sheets)) {
      report_lines <- c(report_lines, paste("- **Sheet Count:** ", length(file_result$sheets)))
      report_lines <- c(report_lines, "")

      for (sheet_name in names(file_result$sheets)) {
        sheet_result <- file_result$sheets[[sheet_name]]

        if (!is.null(sheet_result$error)) {
          report_lines <- c(report_lines, paste("#### ", sheet_name, " (Error)"))
          report_lines <- c(report_lines, paste("❌ ", sheet_result$error))
          report_lines <- c(report_lines, "")
          next
        }

        report_lines <- c(report_lines, paste("#### ", sheet_name))

        if (!is.null(sheet_result$dimensions)) {
          dimensions <- sheet_result$dimensions
          report_lines <- c(report_lines, paste("- **Size:** ", dimensions[1], "rows ×", dimensions[2], "columns"))
        }

        if (!is.null(sheet_result$issues) && length(sheet_result$issues) > 0) {
          report_lines <- c(report_lines, paste("- **Issue Count:** ", length(sheet_result$issues)))
          report_lines <- c(report_lines, "")

          # Sort by severity
          issues_by_severity <- list(
            "high" = list(),
            "medium" = list(),
            "low" = list()
          )

          for (issue in sheet_result$issues) {
            severity <- issue$severity %||% "low"
            issues_by_severity[[severity]] <- append(issues_by_severity[[severity]], list(issue))
          }

          # Output by severity
          severity_names <- c("high" = "🔴 High", "medium" = "🟡 Medium", "low" = "🟢 Low")

          for (severity in c("high", "medium", "low")) {
            severity_issues <- issues_by_severity[[severity]]
            if (length(severity_issues) > 0) {
              report_lines <- c(report_lines, paste("**Severity:", severity_names[severity], "**"))
              report_lines <- c(report_lines, "")

              for (issue in severity_issues) {
                report_lines <- c(report_lines, paste("- **", issue$description, "**"))
                report_lines <- c(report_lines, paste("  - Count: ", issue$count %||% 1))
                if (!is.null(issue$locations)) {
                  locations <- if (length(issue$locations) > 5) {
                    c(head(issue$locations, 5), "...")
                  } else {
                    issue$locations
                  }
                  report_lines <- c(report_lines, paste("  - Location: ", paste(locations, collapse = ", ")))
                }
                report_lines <- c(report_lines, paste("  - Recommendation: ", issue$recommendation))
                report_lines <- c(report_lines, "")
              }
            }
          }
        } else {
          report_lines <- c(report_lines, "✅ **No Issues**")
          report_lines <- c(report_lines, "")
        }
      }
    }
  }

  # Improvement Recommendations
  report_lines <- c(report_lines, "## 🔧 Overall Improvement Recommendations")
  report_lines <- c(report_lines, "")

  if (summary_result$total_issues == 0) {
    report_lines <- c(report_lines, "Congratulations! The data quality of the examined Excel files is excellent.")
  } else {
    report_lines <- c(report_lines, "### Priority-based Improvement Plan")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "1. **🔴 Resolve High Severity Issues**")
    report_lines <- c(report_lines, "   - Unmerge cells")
    report_lines <- c(report_lines, "   - Fix formula errors")
    report_lines <- c(report_lines, "   - Standardize name inconsistencies")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "2. **🟡 Improve Medium Severity Issues**")
    report_lines <- c(report_lines, "   - Normalize data position (start from A1)")
    report_lines <- c(report_lines, "   - Standardize date/unit formats")
    report_lines <- c(report_lines, "   - Convert text-formatted numbers")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "3. **🟢 Clean Up Low Severity Issues**")
    report_lines <- c(report_lines, "   - Remove unnecessary whitespace")
    report_lines <- c(report_lines, "   - Clean up special characters")
    report_lines <- c(report_lines, "   - Standardize placeholders")
  }

  report_lines <- c(report_lines, "")
  report_lines <- c(report_lines, "---")
  report_lines <- c(report_lines, paste("*Report generated at: ", Sys.time(), "*"))
  report_lines <- c(report_lines, "*Generated by: superzarathu::excel_health_check()*")

  # 파일 저장
  report_file <- paste0("sz_excel_report_", timestamp, ".md")
  writeLines(report_lines, report_file, useBytes = TRUE)

  return(report_file)
}