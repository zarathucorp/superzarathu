# superzarathu 0.2.0

## New Features 📊

### Excel Data Quality Assessment
- **New Function**: `excel_health_check()` - Comprehensive Excel data quality assessment
- **AI-Friendly Output**: JSON results with schema for better AI understanding
- **Detailed Reports**: Markdown reports with actionable recommendations
- **Comprehensive Checks**: 19 different quality check types including:
  - Structural problems (merged cells, data positioning, pivot formats)
  - Representation inconsistencies (date formats, units, boolean expressions)
  - Value errors (whitespace, text-formatted numbers, duplicates)
  - Missing data patterns (empty cells, placeholders, implicit missing)
  - Hidden issues (formula errors, encoding problems)

### Dependencies
- **New Dependencies**: Added `openxlsx`, `data.table`, `jsonlite`, `stringdist`
- **Data Preservation**: Read-only approach - never modifies original Excel files
- **R Standards**: Converts empty strings to NA following R conventions

### Output Features
- **Timestamped Files**: `sz_excel_results_YYYYMMDD_HHMMSS.json`
- **JSON Schema**: `sz_excel_schema.json` for AI interoperability
- **Markdown Reports**: `sz_excel_report_YYYYMMDD_HHMMSS.md`
- **Health Scoring**: 0-100 point health score with interpretation

# superzarathu 0.1.0

## Initial Release 🎉

### Features

- **Dual Tool Support**: Generate custom commands for both Gemini CLI and Claude Code
- **Template System**: 6 predefined workflow templates for common data analysis tasks:
  - `preprocess`: Data cleaning and preparation using tidyverse
  - `label`: Data labeling with codebook support
  - `table`: Statistical tables with jstable
  - `plot`: Data visualization with ggplot2 and jskm
  - `rshiny`: Interactive Shiny applications with jsmodule
  - `doctor`: Data quality assessment and health checks

### Functions

- `get_templates()`: Retrieve all available template content
- `setup_gemini_commands()`: Generate TOML command files for Gemini CLI
- `setup_claude_commands()`: Generate markdown slash command files for Claude Code
- `setup_js_document()`: Copy jstable/jskm/jsmodule documentation for AI assistants
- `sz_setup()`: Unified setup function for project structure and AI commands

### Documentation

- Comprehensive vignettes with usage examples
- Function documentation with roxygen2
- Korean medical statistics workflow integration

### Package Infrastructure

- MIT license
- R CMD check compliance
- Comprehensive test suite with testthat
- GitHub Actions CI/CD ready
