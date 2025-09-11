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
