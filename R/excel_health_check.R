#' Null coalescing operator
#' @param x First value
#' @param y Default value if x is NULL
#' @noRd
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Convert column number to Excel column letter(s)
#' @param col_num Column number (1-based)
#' @return Excel column name (A, B, ..., Z, AA, AB, ..., ZZ, AAA, ...)
#' @noRd
col_num_to_excel <- function(col_num) {
  if (is.na(col_num) || col_num < 1) return("A")

  result <- ""
  while (col_num > 0) {
    col_num <- col_num - 1
    result <- paste0(LETTERS[(col_num %% 26) + 1], result)
    col_num <- col_num %/% 26
  }
  return(result)
}

#' Excel Health Check - Excel Data Quality Assessment
#'
#' Comprehensively checks the data quality of Excel files and generates AI-friendly JSON and markdown reports.
#'
#' Check areas: Structural problems, representation inconsistencies, value errors, missing data, hidden issues
#'
#' Important: This function never modifies the original Excel files.
#' Empty strings ('') are automatically treated as NA following R standards.
#' Recommendations are for reference when reading/analyzing data.
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
    message("Original file preservation: Original Excel files will not be modified")
    message("Missing value handling: Empty strings ('') converted to NA for standard processing")
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
    message("Check complete! (Original files were not modified)")
    message("- Check time: ", round(as.numeric(end_time - start_time, units = "secs"), 2), " seconds")
    message("- Files checked: ", length(files), " files")
    message("- Patterns found: ", summary_result$total_issues, " issues")
    message("Recommendations are for reference when reading/analyzing data")
  }

  return(invisible(list(
    summary = summary_result,
    files = all_results
  )))
}

#' Check and load required packages
#' @importFrom utils installed.packages
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
      function() check_merged_cells(wb, sheet_name, data),
      function() check_header_structure(data),
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
# AI Visual Header Detection Helper Functions
# ==============================================

#' Create visual matrix for AI header detection with enhanced context
#' @param data Sheet data
#' @param detected_headers Vector of detected header row indices
#' @param max_rows Maximum rows to analyze (default: 10)
#' @param max_cols Maximum columns to analyze (default: 15)
#' @noRd
create_visual_matrix <- function(data, detected_headers = NULL, max_rows = 10, max_cols = 15) {
  # If headers detected, show them + at least 10 additional rows for context
  if (!is.null(detected_headers) && length(detected_headers) > 0) {
    max_header_row <- max(detected_headers)
    # Show detected headers + 10 additional rows for AI judgment
    max_rows <- min(max_header_row + 10, nrow(data), max_rows)
  }

  max_rows <- min(max_rows, nrow(data))
  max_cols <- min(max_cols, ncol(data))

  visual_matrix <- matrix("", nrow = max_rows, ncol = max_cols)

  for (i in 1:max_rows) {
    for (j in 1:max_cols) {
      cell_val <- as.character(data[i, j])

      if (is.na(cell_val)) {
        visual_matrix[i, j] <- "___"
      } else if (nchar(cell_val) > 15) {
        visual_matrix[i, j] <- "LONG_TEXT"
      } else if (suppressWarnings(!is.na(as.numeric(cell_val)))) {
        visual_matrix[i, j] <- "NUM"
      } else {
        visual_matrix[i, j] <- "TEXT"
      }
    }
  }

  return(visual_matrix)
}

#' Generate enhanced AI judgment with row classifications
#' @param data Sheet data
#' @param visual_matrix Visual representation matrix
#' @param detected_headers Vector of detected header row indices
#' @param header_scores Header scores for detected rows
#' @noRd
generate_enhanced_visualization <- function(data, visual_matrix, detected_headers = NULL, header_scores = NULL) {
  # Classify each row for AI understanding
  row_classifications <- c()
  for (i in 1:nrow(visual_matrix)) {
    if (!is.null(detected_headers) && i %in% detected_headers) {
      # Get score for this header row
      score_idx <- which(detected_headers == i)
      if (!is.null(header_scores) && length(header_scores) >= score_idx) {
        score <- header_scores[score_idx]
        if (score > 0.7) {
          row_classifications[i] <- "HEADER-HIGH"
        } else if (score > 0.5) {
          row_classifications[i] <- "HEADER-MED"
        } else {
          row_classifications[i] <- "HEADER-LOW"
        }
      } else {
        row_classifications[i] <- "HEADER"
      }
    } else {
      row_classifications[i] <- "DATA"
    }
  }

  # Create enhanced visual representation string
  visual_str <- ""
  for (i in 1:nrow(visual_matrix)) {
    row_pattern <- paste(sprintf("%-10s", visual_matrix[i, ]), collapse = " | ")
    classification <- sprintf("[%s]", row_classifications[i])
    visual_str <- paste0(visual_str, sprintf("Row %2d: %s %s\n", i, row_pattern, classification))
  }

  # Extract sample values for all shown rows
  sample_values <- ""
  for (i in 1:min(nrow(visual_matrix), nrow(data))) {
    samples <- c()
    for (j in 1:min(5, ncol(data))) {
      cell <- as.character(data[i, j])
      if (!is.na(cell)) {
        if (nchar(cell) > 15) {
          samples <- c(samples, paste0(substr(cell, 1, 15), "..."))
        } else {
          samples <- c(samples, cell)
        }
      } else {
        samples <- c(samples, "")
      }
    }
    sample_values <- paste0(sample_values, sprintf("Row %d: %s\n", i, paste(samples, collapse=" | ")))
  }

  # Generate enhanced AI judgment hint
  ai_hint <- paste0(
    "=== Header Detection Visualization ===\n",
    "⚠️  ALGORITHM DETECTED (Reference Only): Row ", paste(detected_headers, collapse=", "), "\n",
    if (!is.null(header_scores)) paste("Detection Scores: ", paste(round(header_scores, 3), collapse=", "), "\n") else "",
    "Showing Extended Context (Rows 1-", nrow(visual_matrix), ") for Analysis:\n\n",
    visual_str,
    "\nActual Content Samples:\n",
    sample_values,
    "\nHuman/AI Analysis Guidelines:\n",
    "- Algorithm results are REFERENCE ONLY - examine actual content\n",
    "- Check for CODEBOOK/EXAMPLE rows (e.g., '1-option\\n2-option')\n",
    "- Verify true HEADER rows vs DATA rows vs EXAMPLE rows\n",
    "- HEADER-HIGH/MED/LOW: Algorithm confidence levels\n",
    "- Look for actual data start (usually NUM patterns)\n",
    "- Consider multi-level header structures\n",
    "- Final decision should be based on content analysis above"
  )

  # Return structured data for JSON/Report
  return(list(
    ai_hint = ai_hint,
    visual_matrix = visual_matrix,
    row_classifications = row_classifications,
    sample_values = strsplit(sample_values, "\n")[[1]],
    detected_headers = detected_headers,
    header_scores = header_scores,
    context_rows = nrow(visual_matrix)
  ))
}

#' Calculate comprehensive header score combining multiple factors
#' @param data Sheet data
#' @param row_idx Row index to analyze
#' @noRd
calculate_header_score <- function(data, row_idx) {
  if (row_idx > nrow(data)) return(0)

  row_data <- as.character(data[row_idx, ])
  non_empty <- row_data[!is.na(row_data) & row_data != ""]

  if (length(non_empty) == 0) return(0)

  # 1. String length score (25%)
  avg_length <- mean(nchar(non_empty))
  max_length <- max(nchar(non_empty))
  length_score <- pmin(1, (avg_length / 15) * 0.7 + (max_length / 50) * 0.3)

  # 2. Special character score (20%)
  has_newline <- any(grepl("\\r\\n|\\n", non_empty))
  has_colon <- any(grepl(":", non_empty))
  has_parenthesis <- any(grepl("[()]", non_empty))
  special_score <- (has_newline * 0.4 + has_colon * 0.3 + has_parenthesis * 0.3)

  # 3. Unique ratio score (20%)
  unique_ratio <- length(unique(non_empty)) / length(non_empty)
  unique_score <- pmin(1, unique_ratio * 1.5)

  # 4. Empty pattern score (15%)
  empty_count <- sum(is.na(row_data))
  total_cols <- length(row_data)
  empty_ratio <- empty_count / total_cols
  # High empty ratio can indicate header structure (sparse headers)
  empty_score <- if (empty_ratio > 0.7) 0.8 else if (empty_ratio > 0.3) 0.4 else 0.1

  # 5. Type consistency score (20%)
  numeric_count <- sum(suppressWarnings(!is.na(as.numeric(non_empty))))
  text_ratio <- (length(non_empty) - numeric_count) / length(non_empty)
  type_score <- text_ratio

  # Combined score
  total_score <- length_score * 0.25 + special_score * 0.20 + unique_score * 0.20 +
                empty_score * 0.15 + type_score * 0.20

  return(total_score)
}

# ==============================================
# Structural problem check functions
# ==============================================

#' Check merged cells with structure analysis
#' @param wb Workbook object
#' @param sheet_name Sheet name
#' @param data Sheet data for structure analysis
#' @noRd
check_merged_cells <- function(wb, sheet_name, data = NULL) {
  tryCatch({
    merged_cells <- wb$worksheets[[sheet_name]]$mergedCells

    if (length(merged_cells) > 0) {
      # Analyze merge patterns and locations
      header_merges <- c()
      data_merges <- c()

      for (merge_range in merged_cells) {
        # Extract row numbers from merge range (e.g., "A1:C1" -> row 1)
        if (grepl(":", merge_range)) {
          start_cell <- strsplit(merge_range, ":")[[1]][1]
          row_num <- as.numeric(gsub("[A-Z]+", "", start_cell))

          # Consider first 5 rows as potential header area
          if (!is.na(row_num) && row_num <= 5) {
            header_merges <- c(header_merges, merge_range)
          } else {
            data_merges <- c(data_merges, merge_range)
          }
        }
      }

      # Determine severity and description based on merge location
      if (length(header_merges) > 0 && length(data_merges) == 0) {
        # Only header merges - likely intentional structure
        severity <- "info"
        description <- "Hierarchical header structure detected"
        recommendation <- "This appears to be intentional column grouping. Consider: 1) Creating composite column names from multiple header rows, 2) Using both category and subcategory information when reading data, 3) Documenting the header hierarchy for analysis"
      } else if (length(data_merges) > 0) {
        # Data area merges - problematic for analysis
        severity <- "high"
        description <- "Merged cells found in data area"
        recommendation <- "Data area contains merged cells which can cause analysis issues. Consider: 1) Unmerging cells and filling values, 2) Using fill functions to populate empty cells, 3) Pre-processing the Excel file to normalize structure"
      } else {
        # Mixed or unclear merges
        severity <- "medium"
        description <- "Mixed merged cell structure detected"
        recommendation <- "Complex merge pattern found. Evaluate whether merges represent intentional grouping (headers) or data issues requiring normalization"
      }

      result <- list(
        type = "merged_cells",
        severity = severity,
        count = length(merged_cells),
        locations = merged_cells,
        description = description,
        recommendation = recommendation
      )

      # Add detailed structure information
      if (length(header_merges) > 0) {
        result$header_merges <- header_merges
        result$structure_type = "hierarchical_headers"
      }
      if (length(data_merges) > 0) {
        result$data_merges <- data_merges
      }

      return(result)
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
      locations = paste0(col_num_to_excel(first_col), first_row),
      description = sprintf("Data starts at %s%d instead of A1",
                           col_num_to_excel(first_col), first_row),
      recommendation = "Consider adjusting start position with range or skip options when reading data"
    ))
  }
  return(NULL)
}

#' Check multiple values in one cell
#' @param data Sheet data
#' @importFrom utils head
#' @noRd
check_multiple_values_in_cell <- function(data) {
  if (nrow(data) == 0 || ncol(data) == 0) return(NULL)

  # Find separator patterns (/, |, ;, , etc.)
  separators <- c("/", "\\|", ";", ",", "\u30fb")
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
        multi_value_cells <- c(multi_value_cells, paste0(col_num_to_excel(j), i))
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

#' Check unnecessary summary rows/columns
#' @param data Sheet data
#' @noRd
check_summary_rows <- function(data) {
  if (nrow(data) < 2 || ncol(data) < 2) return(NULL)

  summary_indicators <- c("합계", "소계", "계", "총계", "평균", "합", "sum", "total", "average", "subtotal")
  summary_locations <- c()

  # Check rows
  for (i in 1:nrow(data)) {
    row_text <- paste(tolower(as.character(data[i, ])), collapse = " ")
    if (any(sapply(summary_indicators, function(x) grepl(x, row_text, ignore.case = TRUE)))) {
      summary_locations <- c(summary_locations, paste0("Row ", i))
    }
  }

  # Check columns
  for (j in 1:ncol(data)) {
    col_text <- paste(tolower(as.character(data[, j])), collapse = " ")
    if (any(sapply(summary_indicators, function(x) grepl(x, col_text, ignore.case = TRUE)))) {
      summary_locations <- c(summary_locations, paste0("Column ", col_num_to_excel(j)))
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

#' Check header structure with AI visual judgment
#' @param data Sheet data
#' @noRd
check_header_structure <- function(data) {
  if (nrow(data) < 2 || ncol(data) < 2) return(NULL)

  # Analyze first 7 rows for header patterns (increased from 5)
  max_header_rows <- min(7, nrow(data))

  # Calculate header scores first to inform visualization
  header_scores <- sapply(1:max_header_rows, function(i) {
    calculate_header_score(data, i)
  })

  # Identify header rows using thresholds
  primary_headers <- which(header_scores > 0.6)
  secondary_headers <- which(header_scores > 0.4 & header_scores <= 0.6)

  # Preliminary header detection for visualization
  preliminary_headers <- sort(unique(c(primary_headers, secondary_headers)))

  # Generate enhanced visual matrix with detected headers context
  visual_matrix <- create_visual_matrix(data, preliminary_headers, max_header_rows + 10, min(15, ncol(data)))

  # Check for adjacent header pattern (Row 1 + Row 2 pattern)
  if (length(primary_headers) == 0 && length(secondary_headers) > 0) {
    # Check if Row 1 is obvious header even with lower score
    row1_data <- as.character(data[1, ])
    row1_non_empty <- row1_data[!is.na(row1_data) & row1_data != ""]

    if (length(row1_non_empty) > 0) {
      # Check for header indicators in Row 1
      has_long_text <- any(nchar(row1_non_empty) > 10)
      has_korean <- any(grepl("[ㄱ-ㅎㅏ-ㅣ가-힣]", row1_non_empty))
      has_special_chars <- any(grepl("[():]", row1_non_empty))

      if (has_long_text || has_korean || has_special_chars) {
        primary_headers <- c(1, secondary_headers)
      }
    }
  }

  # Combine all detected headers
  all_headers <- sort(unique(c(primary_headers, secondary_headers)))

  if (length(all_headers) >= 1) {
    # Generate enhanced visualization with row classifications
    enhanced_viz <- generate_enhanced_visualization(data, visual_matrix, all_headers, header_scores[all_headers])

    # Determine structure type and severity
    structure_type <- "single_header"
    severity <- "medium"  # Upgraded from "info"

    if (length(all_headers) > 1) {
      structure_type <- "multi_level_header"
      severity <- "medium"
    }

    # Create description based on detected patterns
    if (length(all_headers) == 1) {
      description <- sprintf("Single header row detected at Row %d", all_headers[1])
      recommendation <- sprintf("Consider using skip=%d parameter when reading data to start from Row %d",
                               all_headers[1], all_headers[1] + 1)
    } else {
      # Check for hierarchical vs codebook pattern
      if (1 %in% all_headers && 2 %in% all_headers) {
        row1 <- as.character(data[1, ])
        row2 <- as.character(data[2, ])

        row1_non_empty <- row1[!is.na(row1) & row1 != ""]
        row2_non_empty <- row2[!is.na(row2) & row2 != ""]

        # Determine if it's hierarchical or sequential
        row2_empty_ratio <- sum(is.na(row2) | row2 == "") / length(row2)

        if (row2_empty_ratio > 0.5) {
          structure_type <- "hierarchical_headers"
          description <- sprintf("Hierarchical header structure detected: Row %d (main headers) + Row %d (sub-headers)",
                                all_headers[1], all_headers[2])
          recommendation <- "Multi-level header structure found. Consider: 1) Creating composite column names (e.g., 'MainCategory_SubCategory'), 2) Reading from data start row with custom column names, 3) Using both header levels for complete context"
        } else {
          structure_type <- "sequential_headers"
          description <- sprintf("Sequential header rows detected in rows %s", paste(all_headers, collapse = ", "))
          recommendation <- "Multiple header rows found. Consider: 1) Determining which row contains the primary column names, 2) Using appropriate skip parameter, 3) Manually handling multi-row header structure"
        }
      } else {
        description <- sprintf("Multi-row header structure detected in rows %s", paste(all_headers, collapse = ", "))
        recommendation <- "Complex header structure detected. Carefully examine the data to determine appropriate reading strategy"
      }
    }

    # Create enhanced result with comprehensive visualization
    result <- list(
      type = "header_structure",
      severity = severity,
      count = length(all_headers),
      structure_type = structure_type,
      header_rows = all_headers,
      header_scores = round(header_scores[all_headers], 3),
      description = description,
      recommendation = recommendation,
      ai_visual_analysis = enhanced_viz$ai_hint,
      visualization = list(
        detected_headers = enhanced_viz$detected_headers,
        header_scores = enhanced_viz$header_scores,
        context_rows = enhanced_viz$context_rows,
        visual_matrix = enhanced_viz$visual_matrix,
        row_classifications = enhanced_viz$row_classifications,
        sample_values = enhanced_viz$sample_values
      ),
      details = list(
        primary_headers = primary_headers,
        secondary_headers = secondary_headers,
        max_rows_analyzed = max_header_rows,
        detection_method = "combined_logic_and_visual"
      )
    )

    return(result)
  }

  return(NULL)
}

# ==============================================
# Representation inconsistency check functions
# ==============================================

#' Check name inconsistency
#' @param data Sheet data
#' @importFrom utils head
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
            column = col_num_to_excel(j),
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
      inconsistent_columns[[col_num_to_excel(j)]] <- pattern_matches
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

#' Check unit inconsistency
#' @param data Sheet data
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
        inconsistent_columns[[paste0(col_num_to_excel(j), "_", group_name)]] <- found_units
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
    "korean" = c("예", "아니오", "있음", "없음", "완료", "미완료")
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
      inconsistent_columns[[col_num_to_excel(j)]] <- found_patterns
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
      inconsistent_categories[[col_num_to_excel(j)]] <- spacing_issues
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
      whitespace_issues[[col_num_to_excel(j)]] <- issues
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
      text_number_columns[[col_num_to_excel(j)]] <- issues
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
  problematic_chars <- c("\\*", "#", "\\n", "\\r", "\\t", "[^\\x20-\\x7E\uac00-\ud7a3]")
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
      special_char_issues[[col_num_to_excel(j)]] <- issues
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
#' @importFrom utils head
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
      severity = "medium",
      count = missing_cells,
      total_percentage = missing_percentage,
      description = sprintf("%.2f%% of all cells are empty", missing_percentage),
      recommendation = "High proportion of NA values detected. Consider using complete.cases() or na.omit() during analysis"
    )

    if (length(high_missing_cols) > 0) {
      result$high_missing_columns <- paste0(sapply(high_missing_cols, col_num_to_excel), " (",
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
        col_name <- col_num_to_excel(j)
        if (is.null(placeholder_found[[col_name]])) {
          placeholder_found[[col_name]] <- list()
        }
        placeholder_found[[col_name]][[placeholder]] <- count
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
          implicit_missing[[paste0(col_num_to_excel(j), i)]] <- empty_count
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
        col_name <- col_num_to_excel(j)
        if (is.null(error_found[[col_name]])) {
          error_found[[col_name]] <- list()
        }
        error_found[[col_name]][[error_pattern]] <- count
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
  encoding_patterns <- c("\u00c3", "\u00e2\u20ac", "\u00c2", "\u00c7", "\u00bf", "\u00be", "\u00bd")
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
      encoding_issues[[col_num_to_excel(j)]] <- issue_count
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


  list(
    total_files = total_files,
    total_issues = total_issues,
    issue_types = issue_types,
    analysis_time = as.numeric(end_time - start_time, units = "secs"),
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}


#' Generate JSON Schema
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
          analysis_time = list(
            type = "number",
            description = "Analysis time required (seconds)"
          ),
          timestamp = list(
            type = "string",
            description = "Check execution time (YYYY-MM-DD HH:MM:SS)"
          )
        ),
        required = list("total_files", "total_issues", "timestamp")
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
                            "merged_cells", "header_structure", "data_start_position", "multiple_values_in_cell",
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
                          enum = list("low", "medium", "high", "info"),
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
                        ),
                        ai_visual_analysis = list(
                          type = "string",
                          description = "AI-readable visualization text for header structure analysis"
                        ),
                        visualization = list(
                          type = "object",
                          description = "Enhanced visualization data for header structure analysis",
                          properties = list(
                            detected_headers = list(
                              type = "array",
                              items = list(type = "integer"),
                              description = "Row numbers detected as headers by algorithm"
                            ),
                            header_scores = list(
                              type = "array",
                              items = list(type = "number"),
                              description = "Confidence scores for detected headers"
                            ),
                            context_rows = list(
                              type = "integer",
                              description = "Number of rows shown for analysis context"
                            ),
                            visual_matrix = list(
                              type = "array",
                              items = list(
                                type = "array",
                                items = list(type = "string")
                              ),
                              description = "Visual representation matrix (TEXT/NUM/LONG_TEXT/___)"
                            ),
                            row_classifications = list(
                              type = "array",
                              items = list(type = "string"),
                              description = "Classification of each row (HEADER-HIGH/MED/LOW/DATA)"
                            ),
                            sample_values = list(
                              type = "array",
                              items = list(type = "string"),
                              description = "Actual sample values for analysis"
                            )
                          )
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
#' @importFrom utils head
#' @noRd
generate_markdown_report <- function(summary_result, all_results) {
  # Generate timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  report_lines <- c()

  # Title
  report_lines <- c(report_lines, "# Excel Data Quality Check Report")
  report_lines <- c(report_lines, "")

  # Summary
  report_lines <- c(report_lines, "## Check Summary")
  report_lines <- c(report_lines, "")
  report_lines <- c(report_lines, paste("- **Check Time:** ", summary_result$timestamp))
  report_lines <- c(report_lines, paste("- **Files Checked:** ", summary_result$total_files, " files"))
  report_lines <- c(report_lines, paste("- **Total Issues:** ", summary_result$total_issues, " issues"))
  report_lines <- c(report_lines, paste("- **Analysis Time:** ", round(summary_result$analysis_time, 2), " seconds"))
  report_lines <- c(report_lines, "")


  # Issue Type Statistics
  if (length(summary_result$issue_types) > 0) {
    report_lines <- c(report_lines, "## Issue Type Statistics")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "| Issue Type | Count | Description |")
    report_lines <- c(report_lines, "|------------|-------|-------------|")

    issue_descriptions <- list(
      "merged_cells" = "Merged cells",
      "header_structure" = "Multi-level header structure",
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
  report_lines <- c(report_lines, "## Detailed Analysis by File")
  report_lines <- c(report_lines, "")

  for (file_name in names(all_results)) {
    file_result <- all_results[[file_name]]

    report_lines <- c(report_lines, paste("###", file_name))
    report_lines <- c(report_lines, "")

    if (!is.null(file_result$error)) {
      report_lines <- c(report_lines, paste("**Error:** ", file_result$error))
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
          report_lines <- c(report_lines, paste("Error: ", sheet_result$error))
          report_lines <- c(report_lines, "")
          next
        }

        report_lines <- c(report_lines, paste("#### ", sheet_name))

        if (!is.null(sheet_result$dimensions)) {
          dimensions <- sheet_result$dimensions
          report_lines <- c(report_lines, paste("- **Size:** ", dimensions[1], "rows x", dimensions[2], "columns"))
        }

        if (!is.null(sheet_result$issues) && length(sheet_result$issues) > 0) {
          report_lines <- c(report_lines, paste("- **Issue Count:** ", length(sheet_result$issues)))
          report_lines <- c(report_lines, "")

          # Sort by severity
          issues_by_severity <- list(
            "high" = list(),
            "medium" = list(),
            "low" = list(),
            "info" = list()
          )

          for (issue in sheet_result$issues) {
            severity <- issue$severity %||% "low"
            issues_by_severity[[severity]] <- append(issues_by_severity[[severity]], list(issue))
          }

          # Output by severity
          severity_names <- c("high" = "High", "medium" = "Medium", "low" = "Low", "info" = "Info")

          for (severity in c("high", "medium", "low", "info")) {
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

                # Add visualization for header structure issues
                if (issue$type == "header_structure" && !is.null(issue$visualization)) {
                  viz <- issue$visualization
                  report_lines <- c(report_lines, "")
                  report_lines <- c(report_lines, "  **Header Structure Visualization:**")
                  report_lines <- c(report_lines, "  ```")
                  report_lines <- c(report_lines, paste("  Detected Headers: Row", paste(viz$detected_headers, collapse=", ")))
                  if (!is.null(viz$header_scores)) {
                    report_lines <- c(report_lines, paste("  Algorithm Scores:", paste(round(viz$header_scores, 3), collapse=", ")))
                  }
                  report_lines <- c(report_lines, paste("  Context Rows: 1-", viz$context_rows))
                  report_lines <- c(report_lines, "")

                  # Visual matrix display
                  for (i in 1:nrow(viz$visual_matrix)) {
                    row_pattern <- paste(sprintf("%-10s", viz$visual_matrix[i, ]), collapse=" | ")
                    classification <- sprintf("[%s]", viz$row_classifications[i])
                    report_lines <- c(report_lines, sprintf("  Row %2d: %s %s", i, row_pattern, classification))
                  }

                  report_lines <- c(report_lines, "")
                  report_lines <- c(report_lines, "  Sample Values:")
                  for (sample_line in viz$sample_values[viz$sample_values != ""]) {
                    report_lines <- c(report_lines, paste("  ", sample_line))
                  }

                  report_lines <- c(report_lines, "")
                  report_lines <- c(report_lines, "  Legend:")
                  report_lines <- c(report_lines, "  - HEADER-HIGH/MED/LOW: Algorithm confidence levels")
                  report_lines <- c(report_lines, "  - DATA: Data content rows")
                  report_lines <- c(report_lines, "  - TEXT/NUM: Cell content types")
                  report_lines <- c(report_lines, "  - ___: Empty cells")
                  report_lines <- c(report_lines, "  ```")
                }

                report_lines <- c(report_lines, "")
              }
            }
          }
        } else {
          report_lines <- c(report_lines, "**No Issues**")
          report_lines <- c(report_lines, "")
        }
      }
    }
  }

  # Improvement Recommendations
  report_lines <- c(report_lines, "## Overall Improvement Recommendations")
  report_lines <- c(report_lines, "")

  if (summary_result$total_issues == 0) {
    report_lines <- c(report_lines, "Congratulations! The data quality of the examined Excel files is excellent.")
  } else {
    report_lines <- c(report_lines, "### Priority-based Improvement Plan")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "1. **Resolve High Severity Issues**")
    report_lines <- c(report_lines, "   - Unmerge cells")
    report_lines <- c(report_lines, "   - Fix formula errors")
    report_lines <- c(report_lines, "   - Standardize name inconsistencies")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "2. **Improve Medium Severity Issues**")
    report_lines <- c(report_lines, "   - Normalize data position (start from A1)")
    report_lines <- c(report_lines, "   - Standardize date/unit formats")
    report_lines <- c(report_lines, "   - Convert text-formatted numbers")
    report_lines <- c(report_lines, "")
    report_lines <- c(report_lines, "3. **Clean Up Low Severity Issues**")
    report_lines <- c(report_lines, "   - Remove unnecessary whitespace")
    report_lines <- c(report_lines, "   - Clean up special characters")
    report_lines <- c(report_lines, "   - Standardize placeholders")
  }

  report_lines <- c(report_lines, "")
  report_lines <- c(report_lines, "---")
  report_lines <- c(report_lines, paste("*Report generated at: ", Sys.time(), "*"))
  report_lines <- c(report_lines, "*Generated by: superzarathu::excel_health_check()*")

  # Save file
  report_file <- paste0("sz_excel_report_", timestamp, ".md")
  writeLines(report_lines, report_file, useBytes = TRUE)

  return(report_file)
}