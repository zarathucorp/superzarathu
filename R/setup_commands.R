#' Get Templates from inst/templates Directory
#'
#' Returns a list of all templates for command generation.
#' Each template is read from markdown files in the inst/templates directory.
#'
#' @return A named list where names are command names and values are template content
#' @export
get_templates <- function() {
  # Get the path to the installed package's templates directory
  templates_dir <- system.file("templates", package = "myrpackage")
  
  # If running in development mode (package not installed), use local path
  if (templates_dir == "") {
    templates_dir <- file.path("inst", "templates")
  }
  
  # List all markdown files in the templates directory
  template_files <- list.files(templates_dir, pattern = "\\.md$", full.names = TRUE)
  
  # Read each template file
  templates <- list()
  for (file in template_files) {
    # Extract the template name from the filename (without .md extension)
    template_name <- tools::file_path_sans_ext(basename(file))
    
    # Read the template content
    templates[[template_name]] <- paste(readLines(file, encoding = "UTF-8"), collapse = "\n")
  }
  
  return(templates)
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
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .toml files in the .gemini/commands/ directory
#' setup_gemini_commands()
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
    prompt_content <- templates[[command_name]]

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM 지시어: ", "", first_line)

    # Construct TOML content
    toml_content <- sprintf(
      'name = "%s"\ndescription = "%s"\nprompt = """\n%s\n"""',
      command_name,
      description,
      prompt_content
    )

    # Write .toml file
    toml_file_path <- file.path(gemini_dir, paste0(command_name, ".toml"))
    con <- file(toml_file_path, "w", encoding = "UTF-8")
    writeLines(toml_content, con)
    close(con)

    message("Created command file: ", toml_file_path)
  }

  message("\nGemini command setup complete from templates.")
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
#'
#' @export
#' @examples
#' \dontrun{
#' # This will create .md files in the .claude/commands/ directory
#' setup_claude_commands()
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
    prompt_content <- templates[[command_name]]

    # Extract description from the first line
    first_line <- strsplit(prompt_content, "\n")[[1]][1]
    description <- gsub("# LLM 지시어: ", "", first_line)

    # Construct Claude Code markdown content with frontmatter
    claude_content <- sprintf(
      "---\ndescription: %s\nargument-hint: [options]\n---\n\n%s",
      description,
      prompt_content
    )

    # Write .md file
    claude_file_path <- file.path(claude_dir, paste0(command_name, ".md"))
    con <- file(claude_file_path, "w", encoding = "UTF-8")
    writeLines(claude_content, con)
    close(con)

    message("Created Claude Code command file: ", claude_file_path)
  }

  message("\nClaude Code command setup complete from templates.")
}