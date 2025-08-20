# superzarathu 0.1.0

## Initial Release 🎉

### Features

- **Dual Tool Support**: Generate custom commands for both Gemini CLI and Claude Code
- **Template System**: 7 predefined workflow templates for common data analysis tasks:
  - `preprocess`: Data cleaning and preparation using tidyverse
  - `label`: Data label with codebook support
  - `analysis`: Statistical analysis with gtsummary
  - `shiny`: Interactive web dashboard creation
  - `jstable`: Korean medical statistics tables
  - `jskm`: Kaplan-Meier survival curve visualization
  - `jsmodule`: Modular Shiny application development

### Functions

- `get_templates()`: Retrieve all available template content
- `setup_gemini_commands()`: Generate TOML command files for Gemini CLI
- `setup_claude_commands()`: Generate markdown slash command files for Claude Code

### Documentation

- Comprehensive vignettes with usage examples
- Function documentation with roxygen2
- Korean medical statistics workflow integration

### Package Infrastructure

- MIT license
- R CMD check compliance
- Comprehensive test suite with testthat
- GitHub Actions CI/CD ready
