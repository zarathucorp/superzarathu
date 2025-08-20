test_that("get_templates returns a list", {
  templates <- get_templates()
  expect_type(templates, "list")
})

test_that("get_templates has expected template names", {
  templates <- get_templates()
  expected_names <- c(
    "analysis", "jskm", "jsmodule", "jstable", 
    "label", "plot", "preprocess", "shiny"
  )
  expect_equal(sort(names(templates)), sort(expected_names))
})

test_that("all templates have correct structure", {
  templates <- get_templates()
  for (name in names(templates)) {
    template <- templates[[name]]
    expect_type(template, "list")
    expect_true("content" %in% names(template))
    expect_type(template$content, "character")
    expect_length(template$content, 1)
  }
})

test_that("templates contain expected content", {
  templates <- get_templates()

  # Each template content should contain instruction text
  for (name in names(templates)) {
    content <- templates[[name]]$content
    # Check that content is not empty
    expect_true(nchar(content) > 0)
  }

  # Specific content checks - use content field
  expect_true(grepl("preprocess|data cleaning", templates$preprocess$content, ignore.case = TRUE))
  expect_true(grepl("label", templates$label$content, ignore.case = TRUE))
  expect_true(grepl("analysis|statistic", templates$analysis$content, ignore.case = TRUE))
  expect_true(grepl("Shiny", templates$shiny$content))
  expect_true(grepl("jstable", templates$jstable$content))
  expect_true(grepl("jskm", templates$jskm$content))
  expect_true(grepl("jsmodule", templates$jsmodule$content))
  expect_true(grepl("plot|graph|visual", templates$plot$content, ignore.case = TRUE))
})
