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

## Available Templates

| Template       | Description                                               |
| -------------- | --------------------------------------------------------- |
| **preprocess** | Data cleaning and preparation using tidyverse             |
| **label**      | Data label and factor conversion with codebook support    |
| **analysis**   | Statistical analysis with gtsummary (Table 1, regression) |
| **shiny**      | Interactive web dashboard creation                        |
| **jstable**    | Korean medical statistics tables using jstable package    |
| **jskm**       | Kaplan-Meier survival curve visualization                 |
| **jsmodule**   | Modular Shiny application development                     |

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
gemini preprocess  # Run data preprocess workflow
gemini analysis      # Generate statistical analysis
gemini shiny         # Create interactive dashboard
```

### For Claude Code Users

```r
library(superzarathu)

# Generate Claude Code slash commands
setup_claude_commands()
```

This creates `.claude/commands/` directory with markdown files. Use in Claude Code:

```
/preprocess  # Run data preprocess workflow
/analysis      # Generate statistical analysis
/shiny         # Create interactive dashboard
```

## Example Workflow

```r
library(superzarathu)

# 1. Setup commands for your preferred tool
setup_gemini_commands()  # or setup_claude_commands()

# 2. Explore available templates
templates <- get_templates()
names(templates)
#> [1] "preprocess" "label"     "analysis"     "shiny"
#> [5] "jstable"      "jskm"         "jsmodule"

# 3. View a specific template
cat(templates$preprocess)
```

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
