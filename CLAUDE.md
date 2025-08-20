# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

This is an R package called "myrpackage" that provides utilities for setting up Gemini CLI custom commands from template files. The package integrates with Gemini CLI to create structured data analysis workflows based on predefined templates.

## Development Commands

### Package Building and Testing

```bash
# Check package for errors and warnings
R CMD check .

# Install package locally for testing
R CMD INSTALL .

# Build package tarball
R CMD build .

# Run tests
R -e "devtools::test()"

# Generate documentation from roxygen comments
R -e "devtools::document()"
```

### Package Installation

```bash
# Install from local source
R -e "devtools::install()"

# Install with dependencies
R -e "devtools::install_deps()"
```

## Architecture and Structure

### Core Functionality

The main function `setup_gemini_commands()` in `R/setup_commands.R` reads markdown template files from the `templates/` directory and converts them into TOML command files for Gemini CLI integration.

### Template System

- **Location**: `templates/` directory
- **Naming Convention**: `template_N_<command_name>.md` (e.g., `template_1_preprocess.md`)
- **Purpose**: Each template defines a specific data analysis workflow:
  - `preprocess`: R data preprocess workflows
  - `label`: Data label procedures
  - `analysis`: Statistical analysis templates
  - `shiny`: Shiny application templates
  - `jstable`: Table generation utilities
  - `jskm`: Kaplan-Meier survival analysis
  - `jsmodule`: Module development templates

### Template Processing Workflow

1. Templates are read from `templates/` directory
2. Command names are extracted from filenames (removes `template_N_` prefix)
3. TOML files are generated in `.gemini/commands/` directory
4. Each TOML file contains the full template content as a prompt

### Dependencies

Key R packages used:

- `dplyr` (>= 1.0.0): Data manipulation
- `ggplot2`: Data visualization
- `yaml`: YAML processing
- `testthat` (>= 3.0.0): Testing framework (suggested)

### Package Structure

- `R/setup_commands.R`: Main function for command setup
- `templates/`: Markdown templates for different analysis workflows
- `man/`: Auto-generated documentation
- `tests/testthat.R`: Test configuration
- `vignettes/`: Package usage documentation

## Working with Templates

### Adding New Templates

1. Create new markdown file in `templates/` following naming convention
2. Start with Korean LLM instruction format: `# LLM 지시어: <description>`
3. Include structured workflow with R code examples
4. Run `setup_gemini_commands()` to generate corresponding TOML file

### Template Structure

Each template should include:

- Objective section (목표)
- Process steps (프로세스) with numbered sections
- R code blocks with comments
- Final deliverable specification (최종 산출물)

## Important Notes

- The package name in DESCRIPTION is "myrpackage" but this appears to be a placeholder
- Templates are written in Korean and focus on biomedical/statistical analysis workflows
- The package integrates with external Gemini CLI tool for command execution
- UTF-8 encoding is enforced for proper Korean text handling
