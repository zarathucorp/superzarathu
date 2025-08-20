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
    analysis = "--data <file> --outcome <var> [--group <var>] [--method <type>]",
    shiny = "--data <file> [--title <text>] [--port <number>]",
    jstable = "--data <file> [--strata <var>] [--vars <var1,var2>]",
    jskm = "--data <file> --time <var> --event <var> [--group <var>]",
    jsmodule = "--data <file> [--modules <module1,module2>] [--title <text>]",
    plot = "--data <file> --type <plot> [--x <var>] [--y <var>] [--output <file>]"
  )
  
  # Read each template file
  templates <- list()
  for (file in template_files) {
    # Extract the template name from the filename (without .md extension)
    template_name <- tools::file_path_sans_ext(basename(file))
    
    # Read the template content
    content <- paste(readLines(file, encoding = "UTF-8"), collapse = "\n")
    
    # Add argument support section at the beginning
    argument_section <- sprintf(
      "## 사용자 입력 인수\n$ARGUMENTS\n\n참고: 사용자가 제공한 옵션을 다음과 같이 해석하세요:\n%s\n\n예시: $ARGUMENTS\n\n",
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
    preprocess = "- --input 또는 첫 번째 인수: 입력 데이터 파일 경로 (CSV/Excel)\n- --output: 출력 RDS 파일 경로 (기본값: processed_data.rds)\n- --encoding: 파일 인코딩 (기본값: UTF-8, 대안: CP949)\n- --chunk-size: 대용량 데이터 처리 시 청크 크기",
    label = "- --data 또는 첫 번째 인수: 전처리된 RDS 데이터 파일\n- --codebook: 코드북 Excel 파일 경로 (선택사항)\n- --output: 출력 RDS 파일 경로 (기본값: labeled_data.rds)",
    analysis = "- --data 또는 첫 번째 인수: 라벨링된 RDS 데이터 파일\n- --outcome: 결과 변수명 (종속변수)\n- --group: 그룹 비교 변수명\n- --covariates: 공변량 변수들 (쉼표로 구분)\n- --method: 분석 방법 (linear, logistic, cox 등)",
    shiny = "- --data 또는 첫 번째 인수: 분석용 RDS 데이터 파일\n- --title: 앱 제목 (기본값: Data Explorer)\n- --port: 앱 실행 포트 (기본값: 자동)\n- --theme: UI 테마 (기본값: default)",
    jstable = "- --data 또는 첫 번째 인수: RDS 데이터 파일\n- --strata: 층화 변수 (그룹 비교용)\n- --vars: Table 1에 포함할 변수들 (쉼표로 구분)\n- --output: 출력 형식 (html, word, excel)",
    jskm = "- --data 또는 첫 번째 인수: RDS 데이터 파일\n- --time: 시간 변수명\n- --event: 이벤트 변수명\n- --group: 그룹 변수명 (선택사항)\n- --timeby: X축 시간 간격 (기본값: 365)",
    jsmodule = "- --data 또는 첫 번째 인수: RDS 데이터 파일\n- --modules: 포함할 모듈들 (data,table1,km,cox 중 선택, 쉼표로 구분)\n- --title: 앱 제목",
    plot = "- --data 또는 첫 번째 인수: RDS 데이터 파일\n- --type: 플롯 유형 (bar, scatter, box, survival 등)\n- --x: X축 변수명\n- --y: Y축 변수명\n- --group: 그룹 변수명\n- --output: PowerPoint 출력 파일명 (기본값: plots.pptx)"
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
#' # Usage: gemini /preprocess --input data.csv --output clean.rds
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
  message("Usage example: gemini /preprocess --input data.csv --output clean.rds")
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
#' # Usage: /preprocess --input data.csv --output clean.rds
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
    description <- gsub("# LLM 지시어: ", "", first_line)

    # Construct Claude Code markdown content with frontmatter
    claude_content <- sprintf(
      "---\ndescription: %s\nargument-hint: %s\n---\n\n%s",
      description,
      argument_hint,
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
  message("Usage example: /preprocess --input data.csv --output clean.rds")
}