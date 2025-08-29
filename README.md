# superzarathu

[![GitHub](https://img.shields.io/badge/GitHub-zarathucorp%2Fsuperzarathu-blue)](https://github.com/zarathucorp/superzarathu)
[![R Package](https://img.shields.io/badge/R%20Package-0.1.0-green)](https://github.com/zarathucorp/superzarathu)

> Generate custom commands for data analysis workflows with AI assistants (Claude Code & Gemini CLI)

[한국어 문서 (Korean Documentation)](README.ko.md)

## Overview

`superzarathu` is an R package that provides intelligent templates and functions to generate custom commands for data analysis workflows. It supports both **Claude Code** and **Gemini CLI**, offering predefined workflows for data preprocessing, labeling, statistical analysis, visualization, and Shiny applications.

### Key Features

- 🤖 **AI-Driven Workflows**: Templates optimized for AI assistants to understand and execute
- 📊 **Data Processing**: Advanced preprocessing with clinical trial data support
- 🩺 **Data Doctor**: Comprehensive data health check and diagnostics
- 🏷️ **Smart Labeling**: Automatic variable labeling with jstable integration
- 📈 **Statistical Analysis**: Templates for Korean medical statistics packages (jstable, jskm, jsmodule)
- 🎨 **Visualization**: Plot generation with ggplot2 and interactive graphics
- ⚡ **Shiny Apps**: Rapid Shiny application development templates

## Installation

You can install the development version from GitHub:

```r
# Using devtools
install.packages("devtools")
devtools::install_github("zarathucorp/superzarathu")

# Using remotes (lighter alternative)
install.packages("remotes")
remotes::install_github("zarathucorp/superzarathu")

# Using pak (modern approach)
install.packages("pak")
pak::pak("zarathucorp/superzarathu")
```

## Quick Start

### Basic Setup

```r
library(superzarathu)

# Setup for Claude Code
sz_setup("claude")

# Setup for Gemini CLI
sz_setup("gemini")
```

### Command Structure

After setup, use natural language commands:

```r
# Data preprocessing
"preprocess the data"
"handle clinical trial data with repeated measures"

# Data health check
"diagnose my data"
"check data health"
"find data problems"

# Data labeling  
"label the data"
"apply jstable labeling"

# Statistical analysis
"create descriptive statistics table"
"perform survival analysis"

# Visualization
"create a forest plot"
"make an interactive plot"

# Shiny app
"create a shiny dashboard"
```

## Available Commands

### Data Processing
- `sz:preprocess` - Data cleaning and transformation
- `sz:doctor` - Data health check and diagnostics
- `sz:label` - Variable labeling and metadata management

### Statistical Analysis
- `sz:table` - Descriptive and analytical tables

### Visualization
- `sz:plot` - Static and interactive plots

### Shiny Development
- `sz:rshiny` - Shiny application templates

## Template Features

### Advanced Data Preprocessing
- 📁 Automatic file detection in `data/raw/`
- 🔄 Clinical trial repeated measures handling (V1, V2, V3)
- 📅 Intelligent date conversion and age calculation
- 🧹 NA handling with multiple strategies
- 📌 pins package integration for S3/local storage

### Data Health Check (Doctor)
- 🎯 Data quality scoring (A+ to F grade)
- 🔍 Automatic pattern detection (repeated measures, clinical trials, surveys)
- ⚠️ Issue identification per column
- ❓ Intelligent question generation for data producers
- 📄 Markdown report generation with detailed diagnostics

### Smart Labeling System
- 🏷️ jstable::mk.lev() integration
- 🔢 Automatic 0/1 to No/Yes conversion
- 📊 Factor/continuous variable classification
- 📖 Codebook detection and application
- 🌐 Multi-language label support

### AI Workflow Approach

Templates use a 2-stage approach:

1. **Exploration Stage** (Direct execution)
   ```bash
   Rscript -e "str(data, list.len=5)"
   ```

2. **Processing Stage** (Script generation)
   ```r
   # Generated script for reproducibility
   source("scripts/preprocess_data.R")
   ```

## Project Structure

The package creates an organized project structure:

```
project/
├── data/
│   ├── raw/        # Original data files
│   └── processed/  # Cleaned data (RDS)
├── scripts/
│   ├── utils/      # Helper functions
│   ├── analysis/   # Analysis scripts
│   └── plots/      # Visualization scripts
├── output/
│   ├── tables/     # Generated tables
│   └── plots/      # Generated plots
└── app.R           # Shiny application
```

## Requirements

### Core Dependencies
- R (≥ 3.5.0)
- data.table
- openxlsx
- ggplot2

### Recommended Packages
- jstable (for medical statistics)
- jskm (for survival curves)
- jsmodule (for Shiny modules)
- pins (for data versioning)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Authors

- **Zarathu Corp** - [office@zarathu.com](mailto:office@zarathu.com)
- **Jaewoong Heo** - [jwheo@zarathu.com](mailto:jwheo@zarathu.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built for seamless integration with Claude Code and Gemini CLI
- Optimized for medical and clinical research workflows
- Templates based on real-world data analysis patterns

## Support

For issues and questions:
- 🐛 [Report bugs](https://github.com/zarathucorp/superzarathu/issues)
- 💡 [Request features](https://github.com/zarathucorp/superzarathu/issues)
- 📧 [Contact support](mailto:office@zarathu.com)