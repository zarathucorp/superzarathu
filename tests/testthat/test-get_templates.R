test_that("get_templates returns a list", {
  templates <- get_templates()
  expect_type(templates, "list")
})

test_that("get_templates has expected template names", {
  templates <- get_templates()
  expected_names <- c(
    "preprocess", "label", "analysis", "shiny",
    "jstable", "jskm", "jsmodule"
  )
  expect_equal(names(templates), expected_names)
})

test_that("all templates are character strings", {
  templates <- get_templates()
  for (template in templates) {
    expect_type(template, "character")
    expect_length(template, 1)
  }
})

test_that("templates contain expected content", {
  templates <- get_templates()

  # Each template should start with "# LLM 지시어:"
  for (template in templates) {
    expect_true(grepl("^# LLM 지시어:", template))
  }

  # Specific content checks
  expect_true(grepl("데이터 전처리", templates$preprocess))
  expect_true(grepl("라벨링", templates$label))
  expect_true(grepl("통계 분석", templates$analysis))
  expect_true(grepl("Shiny", templates$shiny))
  expect_true(grepl("jstable", templates$jstable))
  expect_true(grepl("jskm", templates$jskm))
  expect_true(grepl("jsmodule", templates$jsmodule))
})
