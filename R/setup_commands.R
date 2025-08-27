#' Get Templates from inst/templates Directory
#'
#' Returns a list of all templates for command generation.
#' Each template is read from markdown files in the inst/templates directory.
#' Templates are enhanced with argument hints for both Claude Code and Gemini CLI.
#'
#' @return A named list where names are command names and values are template info
#' @export
get_templates <- function() {
  # Get the path to the installed package's templates directory
  templates_dir <- system.file("templates", package = "superzarathu")
  
  # If running in development mode (package not installed), use local path
  if (templates_dir == "") {
    templates_dir <- file.path("inst", "templates")
  }
  
  # List all markdown files in the templates directory
  template_files <- list.files(templates_dir, pattern = "\\.md$", full.names = TRUE)
  
  # Define argument hints for each template
  argument_hints <- list(
    preprocess = "--input <file> [--output <file>] [--encoding <type>]",
    label = "--data <file> [--codebook <file>] [--output <file>]",
    analysis = "[자유 형식 요청]",  # Natural language request
    shiny = "[자유 형식 요청]",      # Natural language request
    jstable = "--data <file> [--strata <var>] [--vars <var1,var2>]",
    jskm = "--data <file> --time <var> --event <var> [--group <var>]",
    jsmodule = "--data <file> [--modules <module1,module2>] [--title <text>]",
    plot = "[자유 형식 요청]"        # Natural language request
  )
  
  # Read each template file
  templates <- list()
  for (file in template_files) {
    # Extract the template name from the filename (without .md extension)
    template_name <- tools::file_path_sans_ext(basename(file))
    
    # Read the template content
    content <- paste(readLines(file, encoding = "UTF-8"), collapse = "\n")
    
    # Check if this template should skip argument section
    skip_args <- template_name %in% c("analysis", "plot", "shiny")
    
    if (!skip_args) {
      # Add argument support section at the beginning
      argument_section <- sprintf(
        "## \uc0ac\uc6a9\uc790 \uc785\ub825 \uc778\uc218\n$ARGUMENTS\n\n\ucc38\uace0: \uc0ac\uc6a9\uc790\uac00 \uc81c\uacf5\ud55c \uc635\uc158\uc744 \ub2e4\uc74c\uacfc \uac19\uc774 \ud574\uc11d\ud558\uc138\uc694:\n%s\n\n\uc608\uc2dc: $ARGUMENTS\n\n",
        get_argument_description(template_name)
      )
      
      # Insert argument section after the title
      lines <- strsplit(content, "\n")[[1]]
      title_line <- grep("^#\\s+LLM", lines)[1]
      if (!is.na(title_line)) {
        content <- paste(c(
          lines[1:title_line],
          "",
          argument_section,
          lines[(title_line+1):length(lines)]
        ), collapse = "\n")
      }
    } else {
      # For analysis, plot, shiny - add simple request section
      simple_section <- "## \uc0ac\uc6a9\uc790 \uc694\uccad\n$ARGUMENTS\n\n\uc0ac\uc6a9\uc790\uc758 \uc694\uccad\uc744 \ubd84\uc11d\ud558\uc5ec \uc801\uc808\ud55c \ubd84\uc11d, \uc2dc\uac01\ud654, \ub610\ub294 \uc571\uc744 \uc0dd\uc131\ud558\uc138\uc694.\n\uc608\uc2dc: '\ub370\uc774\ud130\ub97c \ubd84\uc11d\ud574\uc918', '\uc0dd\uc874 \ubd84\uc11d \uadf8\ub798\ud504 \uadf8\ub824\uc918', 'Shiny \ub300\uc2dc\ubcf4\ub4dc \ub9cc\ub4e4\uc5b4\uc918'\n\n"
      
      lines <- strsplit(content, "\n")[[1]]
      title_line <- grep("^#\\s+LLM", lines)[1]
      if (!is.na(title_line)) {
        content <- paste(c(
          lines[1:title_line],
          "",
          simple_section,
          lines[(title_line+1):length(lines)]
        ), collapse = "\n")
      }
    }
    
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
  descriptions <- list(
    preprocess = "- --input \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: \uc785\ub825 \ub370\uc774\ud130 \ud30c\uc77c \uacbd\ub85c (CSV/Excel)\n- --output: \ucd9c\ub825 RDS \ud30c\uc77c \uacbd\ub85c (\uae30\ubcf8\uac12: processed_data.rds)\n- --encoding: \ud30c\uc77c \uc778\ucf54\ub529 (\uae30\ubcf8\uac12: UTF-8, \ub300\uc548: CP949)\n- --chunk-size: \ub300\uc6a9\ub7c9 \ub370\uc774\ud130 \ucc98\ub9ac \uc2dc \uccad\ud06c \ud06c\uae30",
    label = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: \uc804\ucc98\ub9ac\ub41c RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --codebook: \ucf54\ub4dc\ubd81 Excel \ud30c\uc77c \uacbd\ub85c (\uc120\ud0dd\uc0ac\ud56d)\n- --output: \ucd9c\ub825 RDS \ud30c\uc77c \uacbd\ub85c (\uae30\ubcf8\uac12: labeled_data.rds)",
    analysis = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: \ub77c\ubca8\ub9c1\ub41c RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --outcome: \uacb0\uacfc \ubcc0\uc218\uba85 (\uc885\uc18d\ubcc0\uc218)\n- --group: \uadf8\ub8f9 \ube44\uad50 \ubcc0\uc218\uba85\n- --covariates: \uacf5\ubcc0\ub7c9 \ubcc0\uc218\ub4e4 (\uc27c\ud45c\ub85c \uad6c\ubd84)\n- --method: \ubd84\uc11d \ubc29\ubc95 (linear, logistic, cox \ub4f1)",
    shiny = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: \ubd84\uc11d\uc6a9 RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --title: \uc571 \uc81c\ubaa9 (\uae30\ubcf8\uac12: Data Explorer)\n- --port: \uc571 \uc2e4\ud589 \ud3ec\ud2b8 (\uae30\ubcf8\uac12: \uc790\ub3d9)\n- --theme: UI \ud14c\ub9c8 (\uae30\ubcf8\uac12: default)",
    jstable = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --strata: \uce35\ud654 \ubcc0\uc218 (\uadf8\ub8f9 \ube44\uad50\uc6a9)\n- --vars: Table 1\uc5d0 \ud3ec\ud568\ud560 \ubcc0\uc218\ub4e4 (\uc27c\ud45c\ub85c \uad6c\ubd84)\n- --output: \ucd9c\ub825 \ud615\uc2dd (html, word, excel)",
    jskm = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --time: \uc2dc\uac04 \ubcc0\uc218\uba85\n- --event: \uc774\ubca4\ud2b8 \ubcc0\uc218\uba85\n- --group: \uadf8\ub8f9 \ubcc0\uc218\uba85 (\uc120\ud0dd\uc0ac\ud56d)\n- --timeby: X\ucd95 \uc2dc\uac04 \uac04\uaca9 (\uae30\ubcf8\uac12: 365)",
    jsmodule = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --modules: \ud3ec\ud568\ud560 \ubaa8\ub4c8\ub4e4 (data,table1,km,cox \uc911 \uc120\ud0dd, \uc27c\ud45c\ub85c \uad6c\ubd84)\n- --title: \uc571 \uc81c\ubaa9",
    plot = "- --data \ub610\ub294 \uccab \ubc88\uc9f8 \uc778\uc218: RDS \ub370\uc774\ud130 \ud30c\uc77c\n- --type: \ud50c\ub86f \uc720\ud615 (bar, scatter, box, survival \ub4f1)\n- --x: X\ucd95 \ubcc0\uc218\uba85\n- --y: Y\ucd95 \ubcc0\uc218\uba85\n- --group: \uadf8\ub8f9 \ubcc0\uc218\uba85\n- --output: PowerPoint \ucd9c\ub825 \ud30c\uc77c\uba85 (\uae30\ubcf8\uac12: plots.pptx)"
  )
  
  return(descriptions[[template_name]] %||% "")
}

#' Setup Custom Gemini Commands from Template Files
#'
#' This function creates Gemini command TOML files in the ".gemini/commands"
#' directory using templates from the inst/templates directory.
#'
#' @details
#' This function reads templates from the inst/templates directory and generates
#' corresponding TOML files for Gemini CLI. Available templates include:
#' preprocess, label, analysis, shiny, jstable, jskm, jsmodule, and plot.
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
  # 1. Define directory
  gemini_dir <- file.path(getwd(), ".gemini", "commands")

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
    
    # Extract the content
    prompt_content <- template_info$content
    
    # For Gemini, replace $ARGUMENTS with {{args}}
    prompt_content <- gsub("\\$ARGUMENTS", "{{args}}", prompt_content)

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM \\uc9c0\\uc2dc\\uc5b4: ", "", first_line)

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

  message("\nGemini command setup complete from templates.")
  message("Usage example: gemini /sz:preprocess --input data.csv --output clean.rds")
}

#' Setup Custom Claude Code Commands from Template Files
#'
#' This function creates Claude Code slash command markdown files in the
#' ".claude/commands" directory using templates from the inst/templates directory.
#'
#' @details
#' This function reads templates from the inst/templates directory and generates
#' corresponding markdown files for Claude Code slash commands. Available templates
#' include: preprocess, label, analysis, shiny, jstable, jskm, jsmodule, and plot.
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
  # 1. Define directory
  claude_dir <- file.path(getwd(), ".claude", "commands")

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
    
    # Extract the content and argument hint
    prompt_content <- template_info$content
    argument_hint <- ifelse(is.null(template_info$argument_hint), 
                            "[options]", 
                            template_info$argument_hint)

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM \\uc9c0\\uc2dc\\uc5b4: ", "", first_line)

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

  message("\nClaude Code command setup complete from templates.")
  message("Usage example: /sz:preprocess --input data.csv --output clean.rds")
}

#' Create Zarathu Project Structure
#'
#' Creates the standard Zarathu project directory structure.
#' @param project_name Name of the project (default: "superzarathu_example_project")
#' @param base_dir Base directory to create the project in (default: current directory)
#' @noRd
create_zarathu_project_structure <- function(project_name = "superzarathu_example_project", 
                                            base_dir = getwd()) {
  project_path <- file.path(base_dir, project_name)
  
  # Check if project already exists
  if (dir.exists(project_path)) {
    message("Project directory '", project_name, "' already exists.")
    return(invisible(FALSE))
  }
  
  # Create main project directory
  dir.create(project_path, recursive = TRUE)
  message("Created project directory: ", project_path)
  
  # Create subdirectories
  subdirs <- c("scripts", "R", "data")
  for (subdir in subdirs) {
    dir_path <- file.path(project_path, subdir)
    dir.create(dir_path, recursive = TRUE)
    message("  Created subdirectory: ", subdir, "/")
  }
  
  # Create main Shiny app files
  ui_content <- "# UI for Shiny application
library(shiny)

shinyUI(fluidPage(
  titlePanel(\"Zarathu Project\"),
  
  sidebarLayout(
    sidebarPanel(
      h4(\"Controls\"),
      # Add UI controls here
    ),
    
    mainPanel(
      h4(\"Results\"),
      # Add output elements here
    )
  )
))"
  
  server_content <- "# Server logic for Shiny application
library(shiny)

shinyServer(function(input, output, session) {
  # Add server logic here
})"
  
  global_content <- "# Global settings and functions
# Load required libraries and data here

library(shiny)
library(dplyr)
library(ggplot2)

# Load data if exists
if (file.exists(\"data/processed_data.rds\")) {
  data <- readRDS(\"data/processed_data.rds\")
}"
  
  # Write main app files
  writeLines(ui_content, file.path(project_path, "ui.R"))
  message("  Created file: ui.R")
  
  writeLines(server_content, file.path(project_path, "server.R"))
  message("  Created file: server.R")
  
  writeLines(global_content, file.path(project_path, "global.R"))
  message("  Created file: global.R")
  
  # Create script templates
  preprocess_content <- "# Data preprocessing script
# Usage: source('scripts/preprocess.R')

library(dplyr)
library(readxl)

# Function to preprocess raw data
preprocess_data <- function(input_file, output_file = \"data/processed_data.rds\") {
  # Read data
  if (grepl(\"\\\\.xlsx?$\", input_file)) {
    data <- read_excel(input_file)
  } else if (grepl(\"\\\\.csv$\", input_file)) {
    data <- read.csv(input_file, stringsAsFactors = FALSE)
  } else {
    stop(\"Unsupported file format\")
  }
  
  # Add preprocessing steps here
  processed_data <- data %>%
    # Remove missing values
    na.omit() %>%
    # Add more preprocessing as needed
    mutate(processed = TRUE)
  
  # Save processed data
  saveRDS(processed_data, output_file)
  message(\"Data preprocessed and saved to: \", output_file)
  
  return(invisible(processed_data))
}"
  
  label_content <- "# Data labeling script
# Usage: source('scripts/label.R')

library(dplyr)
library(readxl)

# Function to apply labels from codebook
label_data <- function(data_file = \"data/processed_data.rds\", 
                      codebook_file = \"data/code_book.xlsx\",
                      output_file = \"data/labeled_data.rds\") {
  # Read data
  data <- readRDS(data_file)
  
  # Read codebook if exists
  if (file.exists(codebook_file)) {
    codebook <- read_excel(codebook_file)
    # Apply labels based on codebook
    # Add labeling logic here
  }
  
  # Save labeled data
  saveRDS(data, output_file)
  message(\"Data labeled and saved to: \", output_file)
  
  return(invisible(data))
}"
  
  visualize_content <- "# Data visualization script
# Usage: source('scripts/visualize.R')

library(ggplot2)
library(dplyr)

# Function to create visualizations
create_visualizations <- function(data_file = \"data/labeled_data.rds\") {
  # Read data
  data <- readRDS(data_file)
  
  # Create sample visualization
  p <- ggplot(data, aes(x = 1:nrow(data))) +
    geom_line() +
    theme_minimal() +
    labs(title = \"Sample Visualization\",
         x = \"Index\",
         y = \"Value\")
  
  return(p)
}"
  
  # Write script files
  writeLines(preprocess_content, file.path(project_path, "scripts", "preprocess.R"))
  message("  Created file: scripts/preprocess.R")
  
  writeLines(label_content, file.path(project_path, "scripts", "label.R"))
  message("  Created file: scripts/label.R")
  
  writeLines(visualize_content, file.path(project_path, "scripts", "visualize.R"))
  message("  Created file: scripts/visualize.R")
  
  # Create R directory file
  run_script_content <- "# Helper function to run with Shiny script
# Usage: source('R/run_with_rshiny_script.R')

run_with_rshiny_script <- function(script_path) {
  # Source the script
  source(script_path)
  
  # Run Shiny app from current directory
  shiny::runApp(getwd())
}"
  
  writeLines(run_script_content, file.path(project_path, "R", "run_with_rshiny_script.R"))
  message("  Created file: R/run_with_rshiny_script.R")
  
  # Create sample data files (placeholders)
  raw_data_note <- "# Place your raw_data.xlsx file here"
  codebook_note <- "# Place your code_book.xlsx file here (optional)"
  
  writeLines(raw_data_note, file.path(project_path, "data", "README.md"))
  writeLines(codebook_note, file.path(project_path, "data", "codebook_README.md"))
  message("  Created data directory with README files")
  
  message("\nZarathu project structure created successfully!")
  message("Project location: ", project_path)
  
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
#' 
#' @details
#' This function performs the following:
#' 1. Creates a standard Zarathu project structure with Shiny app files and scripts
#' 2. Sets up AI assistant commands based on the chosen AI platform
#' 
#' The project structure includes:
#' - ui.R, server.R, global.R for Shiny app
#' - scripts/ directory with preprocess.R, label.R, visualize.R
#' - R/ directory with helper functions
#' - data/ directory for data files
#' 
#' @export
#' @examples
#' \dontrun{
#' # Setup for Claude (default)
#' sz:setup()
#' 
#' # Setup for Gemini
#' sz:setup(ai = "gemini")
#' 
#' # Setup for both Claude and Gemini
#' sz:setup(ai = "both")
#' 
#' # Setup without creating project structure
#' sz:setup(create_project = FALSE)
#' 
#' # Setup with custom project name
#' sz:setup(project_name = "my_analysis_project")
#' }
`sz:setup` <- function(ai = "claude", 
                       project_name = "superzarathu_example_project",
                       create_project = TRUE) {
  
  # Validate ai parameter
  ai <- tolower(ai)
  if (!ai %in% c("claude", "gemini", "both")) {
    stop("ai parameter must be 'claude', 'gemini', or 'both'")
  }
  
  message("=== SuperZarathu Setup ===\n")
  
  # Step 1: Create project structure if requested
  if (create_project) {
    message("Step 1: Creating Zarathu project structure...")
    created <- create_zarathu_project_structure(project_name = project_name)
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
    message("\nProject structure created in: ", file.path(getwd(), project_name))
    message("Next steps:")
    message("  1. Place your raw data in: ", project_name, "/data/raw_data.xlsx")
    message("  2. (Optional) Add codebook: ", project_name, "/data/code_book.xlsx")
    message("  3. Navigate to project: setwd('", project_name, "')")
  }
  
  if (ai == "claude" || ai == "both") {
    message("\nClaude Code commands available:")
    message("  Example: /sz:preprocess --input data/raw_data.xlsx")
  }
  
  if (ai == "gemini" || ai == "both") {
    message("\nGemini CLI commands available:")
    message("  Example: gemini /sz:preprocess --input data/raw_data.xlsx")
  }
  
  invisible(TRUE)
}