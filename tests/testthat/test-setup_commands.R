test_that("setup_gemini_commands creates directory", {
  # Create temporary directory for testing
  temp_dir <- tempdir()
  original_wd <- getwd()

  # Switch to temp directory
  setwd(temp_dir)

  # Clean up any existing .gemini directory
  if (dir.exists(".gemini")) {
    unlink(".gemini", recursive = TRUE)
  }

  # Test function
  expect_message(setup_gemini_commands(), "Created directory")
  expect_true(dir.exists(".gemini/commands"))

  # Check that TOML files are created
  toml_files <- list.files(".gemini/commands", pattern = "\\.toml$")
  expected_files <- c(
    "preprocess.toml", "label.toml", "analysis.toml",
    "shiny.toml", "jstable.toml", "jskm.toml", "jsmodule.toml"
  )
  expect_equal(sort(toml_files), sort(expected_files))

  # Check TOML file content
  preprocess_content <- readLines(".gemini/commands/preprocess.toml")
  expect_true(any(grepl("name = \"preprocess\"", preprocess_content)))
  expect_true(any(grepl("prompt = \"\"\"", preprocess_content)))

  # Clean up
  unlink(".gemini", recursive = TRUE)
  setwd(original_wd)
})

test_that("setup_claude_commands creates directory", {
  # Create temporary directory for testing
  temp_dir <- tempdir()
  original_wd <- getwd()

  # Switch to temp directory
  setwd(temp_dir)

  # Clean up any existing .claude directory
  if (dir.exists(".claude")) {
    unlink(".claude", recursive = TRUE)
  }

  # Test function
  expect_message(setup_claude_commands(), "Created directory")
  expect_true(dir.exists(".claude/commands"))

  # Check that markdown files are created
  md_files <- list.files(".claude/commands", pattern = "\\.md$")
  expected_files <- c(
    "preprocess.md", "label.md", "analysis.md",
    "shiny.md", "jstable.md", "jskm.md", "jsmodule.md"
  )
  expect_equal(sort(md_files), sort(expected_files))

  # Check markdown file content
  preprocess_content <- readLines(".claude/commands/preprocess.md")
  expect_true(any(grepl("^---$", preprocess_content))) # YAML frontmatter
  expect_true(any(grepl("description:", preprocess_content)))
  expect_true(any(grepl("# LLM 지시어:", preprocess_content)))

  # Clean up
  unlink(".claude", recursive = TRUE)
  setwd(original_wd)
})

test_that("commands work when directories already exist", {
  # Create temporary directory for testing
  temp_dir <- tempdir()
  original_wd <- getwd()

  # Switch to temp directory
  setwd(temp_dir)

  # Pre-create directories
  dir.create(".gemini/commands", recursive = TRUE)
  dir.create(".claude/commands", recursive = TRUE)

  # Functions should work without error
  expect_message(setup_gemini_commands(), "complete")
  expect_message(setup_claude_commands(), "complete")

  # Clean up
  unlink(".gemini", recursive = TRUE)
  unlink(".claude", recursive = TRUE)
  setwd(original_wd)
})
