test_that("get_templates returns a list", {
  templates <- get_templates()
  expect_type(templates, "list")
})

test_that("get_templates returns all expected templates", {
  templates <- get_templates()
  
  # Check that templates is a list
  expect_type(templates, "list")
  
  # Check expected templates are present (v2 templates)
  expected_commands <- c("preprocess", "label", "table", "plot", "rshiny", "doctor")
  actual_commands <- names(templates)
  
  # Check all expected commands are present
  for (cmd in expected_commands) {
    expect_true(cmd %in% actual_commands, 
                info = paste("Template", cmd, "should be present"))
  }
  
  # Check each template has required fields
  for (cmd in names(templates)) {
    expect_true("content" %in% names(templates[[cmd]]),
                info = paste("Template", cmd, "should have 'content' field"))
    expect_true("argument_hint" %in% names(templates[[cmd]]),
                info = paste("Template", cmd, "should have 'argument_hint' field"))
    expect_true("supports_args" %in% names(templates[[cmd]]),
                info = paste("Template", cmd, "should have 'supports_args' field"))
    
    # Check content is not empty
    expect_true(nchar(templates[[cmd]]$content) > 0,
                info = paste("Template", cmd, "content should not be empty"))
    
    # Check supports_args is TRUE
    expect_true(templates[[cmd]]$supports_args,
                info = paste("Template", cmd, "should support arguments"))
  }
})

test_that("templates contain expected content", {
  templates <- get_templates()
  
  # Each template content should contain instruction text
  for (name in names(templates)) {
    content <- templates[[name]]$content
    # Check that content is not empty
    expect_true(nchar(content) > 0,
                info = paste("Template", name, "should have content"))
  }
  
  # Specific content checks for v2 templates
  if ("preprocess" %in% names(templates)) {
    expect_true(grepl("전처리|preprocess|data", templates$preprocess$content, ignore.case = TRUE))
  }
  
  if ("label" %in% names(templates)) {
    expect_true(grepl("라벨|label", templates$label$content, ignore.case = TRUE))
  }
  
  if ("table" %in% names(templates)) {
    expect_true(grepl("테이블|table", templates$table$content, ignore.case = TRUE))
  }
  
  if ("plot" %in% names(templates)) {
    expect_true(grepl("plot|그래프|visual", templates$plot$content, ignore.case = TRUE))
  }
  
  if ("rshiny" %in% names(templates)) {
    expect_true(grepl("shiny|앱|app", templates$rshiny$content, ignore.case = TRUE))
  }
  
  if ("doctor" %in% names(templates)) {
    expect_true(grepl("진단|doctor|health|체크", templates$doctor$content, ignore.case = TRUE))
  }
})

test_that("get_argument_description returns expected descriptions", {
  # Test for preprocess
  desc <- get_argument_description("preprocess")
  expect_type(desc, "character")
  expect_true(grepl("전처리|survey|csv", desc, ignore.case = TRUE))
  
  # Test for label
  desc <- get_argument_description("label")
  expect_type(desc, "character")
  expect_true(grepl("라벨|코드북", desc, ignore.case = TRUE))
  
  # Test for table
  desc <- get_argument_description("table")
  expect_type(desc, "character")
  expect_true(grepl("특성표|회귀분석", desc, ignore.case = TRUE))
  
  # Test for plot
  desc <- get_argument_description("plot")
  expect_type(desc, "character")
  expect_true(grepl("생존곡선|박스플롯", desc, ignore.case = TRUE))
  
  # Test for rshiny
  desc <- get_argument_description("rshiny")
  expect_type(desc, "character")
  expect_true(grepl("분석 앱|통계", desc, ignore.case = TRUE))
  
  # Test for doctor
  desc <- get_argument_description("doctor")
  expect_type(desc, "character")
  expect_true(grepl("진단|건강|체크", desc, ignore.case = TRUE))
  
  # Test for non-existent template
  desc <- get_argument_description("nonexistent")
  expect_equal(desc, "")
})