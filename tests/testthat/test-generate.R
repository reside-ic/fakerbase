test_that("maps types from postgres to r", {
  tab <- data.frame(column_name = rep(c("integer_col", "smallint_col", "boolean_col",
                                        "date_col", "numeric_col", "real_col",
                                        "timestamp_without_col", "timestamp_with_col", "varchar_col"), 2),
                    data_type = rep(c("integer", "smallint", "boolean", "date", "numeric", "real",
                                      "timestamp without time zone", "timestamp with time zone", "varchar"), 2),
                    is_nullable = c(rep("NO", 9), rep("YES", 9)))

  type_check <- generate_type_check(tab$column_name, tab$data_type, tab$is_nullable)

  expected <- c("stopifnot(typeof(integer_col) == \"integer\")",
                "stopifnot(typeof(smallint_col) == \"integer\")",
                "stopifnot(typeof(boolean_col) == \"logical\")",
                "stopifnot(typeof(date_col) == \"double\")",
                "stopifnot(typeof(numeric_col) == \"double\")",
                "stopifnot(typeof(real_col) == \"double\")",
                "stopifnot(inherits(timestamp_without_col, \"POSIXct\"))",
                "stopifnot(inherits(timestamp_with_col, \"POSIXct\"))",
                "stopifnot(typeof(varchar_col) == \"character\")",
                "stopifnot(is.na(integer_col) || typeof(integer_col) == \"integer\")",
                "stopifnot(is.na(smallint_col) || typeof(smallint_col) == \"integer\")",
                "stopifnot(is.na(boolean_col) || typeof(boolean_col) == \"logical\")",
                "stopifnot(is.na(date_col) || typeof(date_col) == \"double\")",
                "stopifnot(is.na(numeric_col) || typeof(numeric_col) == \"double\")",
                "stopifnot(is.na(real_col) || typeof(real_col) == \"double\")",
                "stopifnot(is.na(timestamp_without_col) || inherits(timestamp_without_col, \"POSIXct\"))",
                "stopifnot(is.na(timestamp_with_col) || inherits(timestamp_with_col, \"POSIXct\"))",
                "stopifnot(is.na(varchar_col) || typeof(varchar_col) == \"character\")")

  expect_equal(type_check, expected)
})

test_that("method args default to NA if column accepts nulls", {
  tab <- data.frame(table_name = "test_table",
                    column_name = c("nullable", "non-nullable"),
                    data_type = c("integer", "integer"),
                    is_nullable = c("YES", "NO"))
  mock_code <- generate_mock_table(tab)
  expected_first_line <- "fake_test_table <- function(nullable = NA, non-nullable) {"
  expect_equal(unlist(strsplit(mock_code, "\n"))[1], expected_first_line)
})

test_that("can generate a valid function", {
  tab <- data.frame(table_name = "country",
                    column_name = c("id", "name"),
                    data_type = c("integer", "varchar"),
                    is_nullable = c("NO", "YES"))

  mock_code <- generate_mock_table(tab)
  eval(str2expression(mock_code))

  country <- fake_country(c(1L, 2L), c("AFG", "AGH"))
  expect_equal(country$id, c(1L, 2L))
  expect_equal(country$name, c("AFG", "AGH"))
})

test_that("functions handle type checking", {
  tab <- data.frame(table_name = "country",
                    column_name = c("id", "name"),
                    data_type = c("integer", "varchar"),
                    is_nullable = c("NO", "YES"))

  mock_code <- build_mocks(tab)
  eval(str2expression(mock_code))

  valid_id_and_name <- fake_country(1L, "AFG")
  expect_equal(valid_id_and_name$id, 1L)
  expect_equal(valid_id_and_name$name, "AFG")

  no_name <- fake_country(2L)
  expect_equal(no_name$id, 2L)
  expect_true(is.na(no_name$name))

  expect_error(fake_country(), "argument \"id\" is missing, with no default")
  expect_error(fake_country("AFG"), "typeof(id) == \"integer\" is not TRUE", fixed = TRUE)
  expect_error(fake_country(1L, 123), "typeof(name) == \"character\" is not TRUE", fixed = TRUE)
})

test_that("can generate multiple functions", {
  tab <- data.frame(table_name = c("country", "country", "gender", "gender"),
                    column_name = c("id", "name", "id", "code"),
                    data_type = c("integer", "text", "integer", "text"),
                    is_nullable = "NO")

  mock_code <- build_mocks(tab)
  eval(str2expression(mock_code))

  country <- fake_country(1L, "AFG")
  expect_equal(country$id, 1L)
  expect_equal(country$name, "AFG")

  gender <- fake_gender(c(1L, 2L), c("male", "female"))
  expect_equal(gender$id, c(1L, 2L))
  expect_equal(gender$code, c("male", "female"))
})
