# superzarathu

<!-- badges: start -->

[![R-CMD-check](https://github.com/zarathucorp/superzarathu/workflows/R-CMD-check/badge.svg)](https://github.com/zarathucorp/superzarathu/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/superzarathu)](https://CRAN.R-project.org/package=superzarathu)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<!-- badges: end -->

**Generate Custom Commands for Data Analysis Workflows**

`superzarathu` is an R package that simplifies the creation of custom commands for data analysis workflows. It supports both **Gemini CLI** and **Claude Code** by automatically generating command files from predefined templates.

## Features

- 🚀 **Dual Tool Support**: Generate commands for both Gemini CLI and Claude Code
- 📋 **Ready-to-Use Templates**: 7 predefined workflows for common data analysis tasks
- 🇰🇷 **Korean Medical Statistics**: Specialized templates for jstable, jskm, jsmodule packages
- 🔄 **Reproducible Workflows**: Consistent, documented analysis pipelines
- 📦 **Easy Integration**: One-function setup for entire workflow suites
- 🎯 **Argument Support**: Pass file paths and parameters directly to commands

## Available Templates

All commands use the `sz:` prefix (e.g., `/sz:preprocess`, `gemini /sz:analysis`).

| Template       | Description                                               | Named Arguments                                               |
| -------------- | --------------------------------------------------------- | ------------------------------------------------------------- |
| **sz:preprocess** | Data cleaning and preparation using tidyverse             | `--input <file> [--output <file>] [--encoding <type>]`       |
| **sz:label**      | Data label and factor conversion with codebook support    | `--data <file> [--codebook <file>] [--output <file>]`        |
| **sz:analysis**   | Statistical analysis with gtsummary (Table 1, regression) | `--data <file> --outcome <var> [--group <var>] [--method]`   |
| **sz:shiny**      | Interactive web dashboard creation                        | `--data <file> [--title <text>] [--port <number>]`           |
| **sz:jstable**    | Korean medical statistics tables using jstable package    | `--data <file> [--strata <var>] [--vars <var1,var2>]`        |
| **sz:jskm**       | Kaplan-Meier survival curve visualization                 | `--data <file> --time <var> --event <var> [--group <var>]`   |
| **sz:jsmodule**   | Modular Shiny application development                     | `--data <file> [--modules <mod1,mod2>] [--title <text>]`     |
| **sz:plot**       | PowerPoint plot generation and insertion                  | `--data <file> --type <plot> [--x <var>] [--y <var>] [--output]` |

## Installation

Install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("zarathucorp/superzarathu")
```

## Quick Start

### For Gemini CLI Users

```r
library(superzarathu)

# Generate Gemini CLI command files
setup_gemini_commands()
```

This creates `.gemini/commands/` directory with TOML files. Use in terminal:

```bash
# Basic usage
gemini /sz:preprocess  # Run data preprocess workflow
gemini /sz:analysis    # Generate statistical analysis
gemini /sz:shiny       # Create interactive dashboard

# With arguments (named parameters)
gemini /sz:preprocess --input data.csv --output clean_data.rds
gemini /sz:analysis --data data.rds --outcome death --group treatment
gemini /sz:jskm --data data.rds --time survival_time --event status --group treatment
```

### For Claude Code Users

```r
library(superzarathu)

# Generate Claude Code slash commands
setup_claude_commands()
```

This creates `.claude/commands/` directory with markdown files. Use in Claude Code:

```
# Basic usage
/sz:preprocess  # Run data preprocess workflow
/sz:analysis    # Generate statistical analysis
/sz:shiny       # Create interactive dashboard

# With arguments (named parameters)
/sz:preprocess --input data.csv --output clean_data.rds
/sz:analysis --data data.rds --outcome death --group treatment
/sz:jskm --data data.rds --time survival_time --event status --group treatment
```

## Example Workflow

### Complete Analysis Pipeline with Named Arguments

```r
library(superzarathu)

# 1. Setup commands for your preferred tool
setup_claude_commands()  # or setup_gemini_commands()

# 2. Execute complete workflow with Claude Code
```

```bash
# Step 1: Preprocess raw data
/sz:preprocess --input patient_data.csv --output processed.rds --encoding UTF-8

# Step 2: Apply labels from codebook
/sz:label --data processed.rds --codebook codebook.xlsx --output labeled.rds

# Step 3: Generate statistical analysis
/sz:analysis --data labeled.rds --outcome mortality --group treatment --method logistic

# Step 4: Create survival analysis
/sz:jskm --data labeled.rds --time survival_days --event death --group treatment

# Step 5: Build interactive dashboard
/sz:shiny --data labeled.rds --title "Clinical Trial Dashboard" --port 3838

# Step 6: Generate presentation
/sz:plot --data labeled.rds --type survival --output results.pptx
```

### Accessing Template Information

```r
# View all templates
templates <- get_templates()
names(templates)
#> [1] "preprocess" "label"     "analysis"     "shiny"
#> [5] "jstable"      "jskm"         "jsmodule"    "plot"

# View specific template content and arguments
cat(templates$analysis$content)

## Template Details

### Data Analysis Pipeline

1. **preprocess**: Clean raw data (CSV/Excel) → RDS output
2. **label**: Apply human-readable labels using codebooks
3. **analysis**: Generate Table 1 and regression analysis with gtsummary
4. **shiny**: Create interactive exploration dashboard

### Korean Medical Statistics

- **jstable**: Publication-ready tables using `mk.lev()` and `CreateTableOneJS()`
- **jskm**: Kaplan-Meier plots with `jskm()` package
- **jsmodule**: Modular Shiny apps with pre-built components

## Documentation

- [Getting Started Guide](https://zarathucorp.github.io/superzarathu/articles/superzarathu-intro.html)
- [Advanced Usage](https://zarathucorp.github.io/superzarathu/articles/advanced-usage.html)
- [Function Reference](https://zarathucorp.github.io/superzarathu/reference/)

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

## License

MIT License. See [LICENSE](LICENSE) file for details.

## About Zarathu

[Zarathu Corp](https://www.zarathu.com) specializes in medical statistics and data science consulting. We develop R packages and provide statistical analysis services for clinical research and healthcare data.

---

**Contact**: contact@zarathu.com | **Website**: https://www.zarathu.com
