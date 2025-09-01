#' Convert Template Placeholders for Different AI Systems
#'
#' Converts template placeholders to the appropriate format for each AI system
#'
#' @param content Template content
#' @param ai_type Type of AI system ("claude" or "gemini")
#' @return Converted content
convert_placeholder <- function(content, ai_type = "claude") {
  if (ai_type == "claude") {
    # Claude Code uses $ARGUMENTS
    content <- gsub("`\\{\\{USER_ARGUMENTS\\}\\}`", "$ARGUMENTS", content)
    content <- gsub("\\{\\{USER_ARGUMENTS\\}\\}", "$ARGUMENTS", content)
  } else if (ai_type == "gemini") {
    # Gemini uses {{args}}
    content <- gsub("`\\{\\{USER_ARGUMENTS\\}\\}`", "{{args}}", content)
    content <- gsub("\\{\\{USER_ARGUMENTS\\}\\}", "{{args}}", content)
  }
  return(content)
}

#' Get Templates from inst/templates Directory
#'
#' Returns a list of all templates for command generation.
#' Each template is read from markdown files in the inst/templates directory.
#' Templates are enhanced with argument hints for both Claude Code and Gemini CLI.
#'
#' @return A named list where names are command names and values are template info
#' @export
get_templates <- function() {
  # Use the commands directory
  subdir <- "commands"

  # Get the path to the installed package's templates directory
  templates_dir <- system.file("templates", subdir, package = "superzarathu")

  # If running in development mode (package not installed), use local path
  if (templates_dir == "") {
    # Try to find the package directory
    pkg_dir <- "/Users/zarathu/projects/superzarathu"
    if (dir.exists(pkg_dir)) {
      templates_dir <- file.path(pkg_dir, "inst", "templates", subdir)
    } else {
      templates_dir <- file.path("inst", "templates", subdir)
    }
  }

  # List all markdown files in the templates directory
  template_files <- list.files(templates_dir, pattern = "\\.md$", full.names = TRUE)

  # Simplified argument hints - mostly natural language now
  argument_hints <- list(
    preprocess = "[natural language request]",
    label = "[natural language request]",
    table = "[natural language request]",
    plot = "[natural language request]",
    rshiny = "[natural language request]",
    doctor = "[natural language request]"
  )

  # Read each template file
  templates <- list()
  for (file in template_files) {
    # Extract the template name from the filename (without .md extension)
    template_name <- tools::file_path_sans_ext(basename(file))

    # Skip README or other non-command files
    if (template_name %in% c("README", "TEMPLATE_SYNTAX")) {
      next
    }

    # Read the template content
    content <- paste(readLines(file, encoding = "UTF-8"), collapse = "\n")

    # Content already has {{USER_ARGUMENTS}} placeholder
    # No need to add argument sections as they're already in the templates

    # Create template info
    templates[[template_name]] <- list(
      content = content,
      argument_hint = argument_hints[[template_name]],
      supports_args = TRUE
    )
  }

  return(templates)
}

#' Get Argument Description for Template
#'
#' Returns a formatted description of arguments for each template
#'
#' @param template_name Name of the template
#' @return Character string with argument descriptions
get_argument_description <- function(template_name) {
  # Simplified descriptions - focus on natural language
  descriptions <- list(
    preprocess = "Examples:\n- '최신 데이터 전처리해줘'\n- 'survey_2024.csv 파일 정제해줘'\n- 'raw 폴더의 모든 CSV 파일 처리해줘'",
    label = "Examples:\n- '데이터에 라벨 붙여줘'\n- '코드북 적용해서 라벨링해줘'\n- '변수명 보고 자동으로 한글 라벨 만들어줘'",
    table = "Examples:\n- '기초 특성표 만들어줘'\n- '치료군별로 특성 비교표 만들어줘'\n- '회귀분석 결과 테이블로 정리해줘'",
    plot = "Examples:\n- '생존곡선 그려줘'\n- '연령별 혈압 분포를 박스플롯으로 보여줘'\n- '변수들 간의 상관관계 히트맵 보여줘'",
    rshiny = "Examples:\n- '데이터 분석 앱 만들어줘'\n- '의학통계 분석 앱 만들어줘'\n- '생존분석 전용 앱 만들어줘'",
    doctor = "Examples:\n- '데이터 진단해줘'\n- '데이터 건강 체크해줘'\n- '엑셀 파일 문제점 찾아줘'"
  )

  return(descriptions[[template_name]] %||% "")
}

#' Setup Custom Gemini Commands from Template Files
#'
#' This function creates Gemini command TOML files in the ".gemini/commands"
#' directory using templates from the inst/templates directory.
#'
#' @param version Template version to use ("v1" or "v2", default: "v2")
#'
#' @details
#' This function reads templates from the inst/templates directory and generates
#' corresponding TOML files for Gemini CLI.
#' v2: 6 commands (preprocess, label, table, plot, rshiny, doctor)
#' v1: 8 commands (preprocess, label, analysis, shiny, jstable, jskm, jsmodule, plot)
#' Commands support arguments using the {{args}} placeholder in Gemini CLI.
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .toml files in the .gemini/commands/ directory
#' setup_gemini_commands()
#' # Usage: gemini /sz:preprocess --input data.csv --output clean.rds
#' }
setup_gemini_commands <- function() {
  # 1. Define directories
  gemini_dir <- file.path(getwd(), ".gemini", "commands")
  gemini_root <- file.path(getwd(), ".gemini")

  # Create .gemini/commands directory if it doesn't exist
  if (!dir.exists(gemini_dir)) {
    dir.create(gemini_dir, recursive = TRUE)
    message("Created directory: ", gemini_dir)
  }

  # 2. Get templates from inst/templates
  templates <- get_templates()

  # 3. Create .toml files for each template
  for (command_name in names(templates)) {
    template_info <- templates[[command_name]]

    # Convert placeholders for Gemini
    prompt_content <- convert_placeholder(template_info$content, "gemini")

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM.*: ", "", first_line)

    # Construct TOML content
    toml_content <- sprintf(
      'name = "%s"\ndescription = "%s"\nprompt = """\n%s\n"""',
      command_name,
      description,
      prompt_content
    )

    # Write .toml file with sz: prefix
    toml_file_path <- file.path(gemini_dir, paste0("sz:", command_name, ".toml"))
    con <- file(toml_file_path, "w", encoding = "UTF-8")
    writeLines(toml_content, con)
    close(con)

    message("Created command file: ", toml_file_path)
  }

  # 4. Create GEMINI.md with common instructions
  create_gemini_md(gemini_root)

  message("\nGemini command setup complete from templates.")
  message("6 commands available: preprocess, label, table, plot, rshiny, doctor")
  message("Common instructions: .gemini/GEMINI.md")
  message("Usage examples:")
  message("  gemini /sz:preprocess '최신 데이터 전처리해줘'")
  message("  gemini /sz:table '기초 특성표 만들어줘'")
}

#' Setup Custom Claude Code Commands from Template Files
#'
#' This function creates Claude Code slash command markdown files in the
#' ".claude/commands" directory using templates from the inst/templates directory.
#'
#' @param version Template version to use ("v1" or "v2", default: "v2")
#'
#' @details
#' This function reads templates from the inst/templates directory and generates
#' corresponding markdown files for Claude Code slash commands.
#' v2: 6 commands (preprocess, label, table, plot, rshiny, doctor)
#' v1: 8 commands (preprocess, label, analysis, shiny, jstable, jskm, jsmodule, plot)
#' Claude Code slash commands use markdown format with YAML frontmatter.
#' Commands support arguments using the $ARGUMENTS placeholder.
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .md files in the .claude/commands/ directory
#' setup_claude_commands()
#' # Usage: /sz:preprocess --input data.csv --output clean.rds
#' }
setup_claude_commands <- function() {
  # 1. Define directories
  claude_dir <- file.path(getwd(), ".claude", "commands")
  claude_root <- file.path(getwd(), ".claude")

  # Create .claude/commands directory if it doesn't exist
  if (!dir.exists(claude_dir)) {
    dir.create(claude_dir, recursive = TRUE)
    message("Created directory: ", claude_dir)
  }

  # 2. Get templates from inst/templates
  templates <- get_templates()

  # 3. Create .md files for each template
  for (command_name in names(templates)) {
    template_info <- templates[[command_name]]

    # Convert placeholders for Claude
    prompt_content <- convert_placeholder(template_info$content, "claude")

    # Extract the argument hint
    argument_hint <- ifelse(is.null(template_info$argument_hint),
      "[options]",
      template_info$argument_hint
    )

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM.*: ", "", first_line)

    # Construct Claude Code markdown content with frontmatter
    claude_content <- sprintf(
      "---\ndescription: %s\nargument-hint: %s\n---\n\n%s",
      description,
      argument_hint,
      prompt_content
    )

    # Write .md file with sz: prefix
    claude_file_path <- file.path(claude_dir, paste0("sz:", command_name, ".md"))
    con <- file(claude_file_path, "w", encoding = "UTF-8")
    writeLines(claude_content, con)
    close(con)

    message("Created Claude Code command file: ", claude_file_path)
  }

  # 4. Create CLAUDE.md with common instructions
  create_claude_md(claude_root)

  message("\nClaude Code command setup complete from templates.")
  message("6 commands available: preprocess, label, table, plot, rshiny, doctor")
  message("Common instructions: .claude/CLAUDE.md")
  message("Usage examples:")
  message("  /sz:preprocess '최신 데이터 전처리해줘'")
  message("  /sz:table '기초 특성표 만들어줘'")
}

#' Create CLAUDE.md for Claude Code
#'
#' Creates a CLAUDE.md file with common instructions for Claude Code
#' @param claude_root Path to .claude directory
#' @noRd
create_claude_md <- function(claude_root) {
  # Get common instructions template
  template_path <- system.file("templates", "COMMON_INSTRUCTIONS.md", package = "superzarathu")

  # If running in development mode, use local path
  if (template_path == "") {
    pkg_dir <- "/Users/zarathu/projects/superzarathu"
    if (dir.exists(pkg_dir)) {
      template_path <- file.path(pkg_dir, "inst", "templates", "COMMON_INSTRUCTIONS.md")
    } else {
      template_path <- file.path("inst", "templates", "COMMON_INSTRUCTIONS.md")
    }
  }

  if (!file.exists(template_path)) {
    warning("Common instructions template not found")
    return()
  }

  # Read template
  content <- paste(readLines(template_path, encoding = "UTF-8"), collapse = "\n")

  # Add Claude-specific header
  claude_content <- paste0(
    "# CLAUDE.md\n\n",
    "이 파일은 Claude Code (claude.ai/code)가 이 프로젝트에서 작업할 때 참고하는 지시사항입니다.\n\n",
    content
  )

  # Write CLAUDE.md
  claude_md_path <- file.path(claude_root, "CLAUDE.md")
  writeLines(claude_content, claude_md_path)
  message("Created Claude common instructions: ", claude_md_path)
}

#' Create GEMINI.md for Gemini CLI
#'
#' Creates a GEMINI.md file with common instructions for Gemini CLI
#' @param gemini_root Path to .gemini directory
#' @noRd
create_gemini_md <- function(gemini_root) {
  # Get common instructions template
  template_path <- system.file("templates", "COMMON_INSTRUCTIONS.md", package = "superzarathu")

  # If running in development mode, use local path
  if (template_path == "") {
    pkg_dir <- "/Users/zarathu/projects/superzarathu"
    if (dir.exists(pkg_dir)) {
      template_path <- file.path(pkg_dir, "inst", "templates", "COMMON_INSTRUCTIONS.md")
    } else {
      template_path <- file.path("inst", "templates", "COMMON_INSTRUCTIONS.md")
    }
  }

  if (!file.exists(template_path)) {
    warning("Common instructions template not found")
    return()
  }

  # Read template
  content <- paste(readLines(template_path, encoding = "UTF-8"), collapse = "\n")

  # Add Gemini-specific header
  gemini_content <- paste0(
    "# GEMINI.md\n\n",
    "이 파일은 Gemini CLI가 이 프로젝트에서 작업할 때 참고하는 지시사항입니다.\n\n",
    content
  )

  # Write GEMINI.md
  gemini_md_path <- file.path(gemini_root, "GEMINI.md")
  writeLines(gemini_content, gemini_md_path)
  message("Created Gemini common instructions: ", gemini_md_path)
}

#' Create Zarathu Project Structure
#'
#' Creates the standard Zarathu project directory structure based on R_PROJECT_TEMPLATE.md.
#' @param project_name Name of the project (default: "superzarathu_example_project")
#' @param base_dir Base directory to create the project in (default: current directory)
#' @param type Project type: "analysis", "shiny", or "both" (default: "both")
#' @noRd
create_zarathu_project_structure <- function(project_name = "superzarathu_example_project",
                                             base_dir = getwd(),
                                             type = "both") {
  # Use current directory as project path
  project_path <- base_dir

  message("Setting up project structure in: ", project_path)
  message("Project type: ", type)

  # Get the path to the template directory
  template_dir <- system.file("templates", "structure", package = "superzarathu")

  # If running in development mode (package not installed), use local path
  if (template_dir == "") {
    # Try to find the package directory
    pkg_dir <- "/Users/zarathu/projects/superzarathu"
    if (dir.exists(pkg_dir)) {
      template_dir <- file.path(pkg_dir, "inst", "templates", "structure")
    } else {
      template_dir <- file.path("inst", "templates", "structure")
    }
  }

  if (!dir.exists(template_dir)) {
    stop("Template directory not found. Please ensure the package is properly installed.")
  }

  # Define directories based on project type
  dirs <- c(
    "data/raw",
    "data/processed",
    "scripts/utils",
    "scripts/analysis",
    "scripts/plots",
    "scripts/tables",
    "output/plots",
    "output/tables",
    "output/reports",
    "docs"
  )

  # Create directories
  for (dir in dirs) {
    dir_path <- file.path(project_path, dir)
    if (!dir.exists(dir_path)) {
      dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
      message("  Created directory: ", dir, "/")
    }
  }

  # Copy template files based on type
  files_to_copy <- list()

  # Analysis files
  if (type == "analysis" || type == "both") {
    files_to_copy <- c(files_to_copy, list(
      c("global.R", "global.R"),
      c("run_analysis.R", "run_analysis.R"),
      c(".gitignore", ".gitignore"),
      c("scripts/utils/preprocess_functions.R", "scripts/utils/preprocess_functions.R"),
      c("scripts/utils/label_functions.R", "scripts/utils/label_functions.R"),
      c("scripts/utils/helper_functions.R", "scripts/utils/helper_functions.R"),
      c("scripts/analysis/01_exploratory.R", "scripts/analysis/01_exploratory.R"),
      c("scripts/analysis/02_statistical.R", "scripts/analysis/02_statistical.R"),
      c("scripts/analysis/03_modeling.R", "scripts/analysis/03_modeling.R"),
      c("scripts/plots/plot_basic.R", "scripts/plots/plot_basic.R"),
      c("scripts/plots/plot_static.R", "scripts/plots/plot_static.R"),
      c("scripts/tables/table_basic.R", "scripts/tables/table_basic.R"),
      c("scripts/tables/table_export.R", "scripts/tables/table_export.R")
    ))
  }

  # Shiny files
  if (type == "shiny" || type == "both") {
    files_to_copy <- c(files_to_copy, list(
      c("app.R", "app.R"),
      c("scripts/plots/plot_interactive.R", "scripts/plots/plot_interactive.R"),
      c("scripts/tables/table_dt.R", "scripts/tables/table_dt.R")
    ))
  }

  # Copy files from template directory
  for (file_pair in files_to_copy) {
    src <- file.path(template_dir, file_pair[1])
    dest <- file.path(project_path, file_pair[2])

    if (file.exists(src)) {
      # Ensure destination directory exists
      dest_dir <- dirname(dest)
      if (!dir.exists(dest_dir)) {
        dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
      }

      # Copy file
      file.copy(src, dest, overwrite = FALSE)
      message("  Created file: ", file_pair[2])
    }
  }

  # Create README with project information
  readme_content <- paste0(
    "# ", project_name, "\n\n",
    "## Project Overview\n",
    "[Add project description here]\n\n",
    "## Data\n",
    "- **Raw Data**: `data/raw/`\n",
    "- **Processed Data**: `data/processed/`\n\n",
    "## Quick Start\n\n"
  )

  if (type == "analysis" || type == "both") {
    readme_content <- paste0(
      readme_content,
      "### Running Analysis\n",
      "```r\n",
      'source("global.R")\n',
      "results <- run_analysis()\n",
      "```\n\n"
    )
  }

  if (type == "shiny" || type == "both") {
    readme_content <- paste0(
      readme_content,
      "### Running Shiny App\n",
      "```r\n",
      "shiny::runApp()\n",
      "# Or with options:\n",
      "shiny::runApp(port = 3838, launch.browser = TRUE)\n",
      "```\n\n"
    )
  }

  readme_content <- paste0(
    readme_content,
    "## Results\n",
    "- **Tables**: `output/tables/`\n",
    "- **Plots**: `output/plots/`\n",
    "- **Reports**: `output/reports/`\n\n",
    "## Project Structure\n",
    "```\n",
    paste(list.files(project_path, recursive = FALSE), collapse = "\n"),
    "\n```\n\n",
    "## Created\n",
    "- Date: ", Sys.Date(), "\n",
    "- Using: superzarathu package\n"
  )

  writeLines(readme_content, file.path(project_path, "README.md"))
  message("  Created file: README.md")

  # Create .gitkeep files for empty directories
  empty_dirs <- c(
    "data/raw", "data/processed", "output/plots",
    "output/tables", "output/reports", "docs"
  )
  for (dir in empty_dirs) {
    gitkeep_path <- file.path(project_path, dir, ".gitkeep")
    if (!file.exists(gitkeep_path)) {
      writeLines("", gitkeep_path)
    }
  }

  message("\n✅ Zarathu project structure created successfully!")
  message("Project type: ", type)
  message("Location: ", project_path)

  return(invisible(TRUE))
}

#' Setup SuperZarathu Commands
#'
#' Unified function to set up SuperZarathu commands for AI assistants and create
#' project structure. By default uses Claude, but can be configured for Gemini.
#'
#' @param ai Character string specifying which AI to setup for. Options are
#'   "claude" (default), "gemini", or "both".
#' @param project_name Character string for the project directory name
#'   (default: "superzarathu_example_project")
#' @param create_project Logical, whether to create the project structure
#'   (default: TRUE)
#' @param type Project type: "analysis", "shiny", or "both" (default: "both")
#' @details
#' This function performs the following:
#' 1. Creates a standard Zarathu project structure based on R_PROJECT_TEMPLATE.md
#' 2. Sets up AI assistant commands based on the chosen AI platform
#' 6 commands available: preprocess, label, table, plot, rshiny, doctor
#'
#' The project structure follows the integrated template with:
#' - data/ directory (raw/processed subdirectories)
#' - scripts/ directory (utils/analysis/plots/tables subdirectories)
#' - shiny/ directory (optional, with modules)
#' - output/ directory (plots/tables/reports subdirectories)
#' - docs/ directory for documentation
#'
#' @export
#' @examples
#' \dontrun{
#' # Setup with default settings
#' sz_setup()
#'
#' # Setup for analysis project only
#' sz_setup(type = "analysis")
#'
#' # Setup for Shiny project only
#' sz_setup(type = "shiny")
#'
#' # Setup for Gemini
#' sz_setup(ai = "gemini")
#'
#' # Setup for both Claude and Gemini
#' sz_setup(ai = "both")
#'
#' # Setup without creating project structure
#' sz_setup(create_project = FALSE)
#'
#' # Setup with custom project name
#' sz_setup(project_name = "my_analysis_project")
#' }
sz_setup <- function(ai = "claude",
                     project_name = "superzarathu_example_project",
                     create_project = TRUE,
                     type = "both") {
  # Validate ai parameter
  ai <- tolower(ai)
  if (!ai %in% c("claude", "gemini", "both")) {
    stop("ai parameter must be 'claude', 'gemini', or 'both'")
  }

  # Validate type parameter
  type <- tolower(type)
  if (!type %in% c("analysis", "shiny", "both")) {
    stop("type parameter must be 'analysis', 'shiny', or 'both'")
  }

  message("=== SuperZarathu Setup ===\n")

  # Step 1: Create project structure if requested
  if (create_project) {
    message("Step 1: Creating Zarathu project structure...")
    # Get current working directory (where the user is running the command from)
    current_dir <- getwd()
    created <- create_zarathu_project_structure(
      project_name = project_name,
      base_dir = current_dir,
      type = type
    )
    if (!created) {
      message("  Skipping project creation (already exists)")
    }
    message("")
  } else {
    message("Step 1: Skipping project structure creation (create_project = FALSE)\n")
  }

  # Step 2: Setup AI commands
  message("Step 2: Setting up AI assistant commands...")

  if (ai == "claude" || ai == "both") {
    message("\nSetting up Claude Code commands...")
    setup_claude_commands()
  }

  if (ai == "gemini" || ai == "both") {
    message("\nSetting up Gemini CLI commands...")
    setup_gemini_commands()
  }

  # Final message
  message("\n=== Setup Complete ===")

  if (create_project) {
    message("\nProject structure created in current directory")
    message("Project type: ", type)
    message("\nNext steps:")
    message("  1. Place your raw data in: data/raw/")
    message("  2. (Optional) Add codebook in: data/raw/")

    if (type == "analysis" || type == "both") {
      message("  3. Run analysis: source('global.R'); run_analysis()")
    }

    if (type == "shiny" || type == "both") {
      message("  3. Run Shiny app: shiny::runApp()")
    }
  }

  if (ai == "claude" || ai == "both") {
    message("\nClaude Code commands available:")
    message("  6 commands: /sz:preprocess, /sz:label, /sz:table, /sz:plot, /sz:rshiny, /sz:doctor")
    message("  Common instructions: .claude/CLAUDE.md")
    message("  Examples (natural language):")
    message("    /sz:preprocess '최신 데이터 전처리해줘'")
    message("    /sz:table '치료군별 기초 특성표 만들어줘'")
    message("    /sz:plot '생존곡선 그려줘'")
    message("    /sz:rshiny '데이터 분석 앱 만들어줘'")
  }

  if (ai == "gemini" || ai == "both") {
    message("\nGemini CLI commands available:")
    message("  6 commands: preprocess, label, table, plot, rshiny, doctor")
    message("  Common instructions: .gemini/GEMINI.md")
    message("  Example: gemini /sz:table '기초 특성표 만들어줘'")
  }

  invisible(TRUE)
}
