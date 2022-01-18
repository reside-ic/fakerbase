test_that("maps types from postgres to r", {
  tab <- data.frame(table_name = "test",
                    column_name = c("integer_col", "smallint_col", "boolean_col",
                                    "date_col", "numeric_col", "real_col",
                                    "timestamp_without_col", "timestamp_with_col", "varchar_col"),
                    data_type = c("integer", "smallint", "boolean", "date", "numeric", "real",
                                  "timestamp without time zone", "timestamp with time zone", "varchar"))

  tab <- tables_with_types(tab)

  expected <- c("integer", "integer", "logical", "POSIXct", "double", "double",
                "POSIXct", "POSIXct", "character")

  expect_equal(tab[[1]]$r_type, expected)
})

test_that("method args default to NA if column accepts nulls", {
  tab <- data.frame(table_name = "test_table",
                    column_name = c("int", "real", "bool", "date", "char", "non_nullable"),
                    r_type = c("integer", "numeric", "logical", "POSIXct", "character", "character"),
                    is_nullable = c(rep("YES", 5), "NO"))
  fn <- build(tab)
  expected_args <- alist(int = NA_integer_, real = NA_real_, bool = NA, date = NA_real_, char = NA_character_, non_nullable = )
  expect_equal(as.list(formals(fn)), expected_args)
})

test_that("can generate a valid function", {
  tab <- data.frame(table_name = "country",
                    column_name = c("id", "name"),
                    r_type = c("integer", "character"),
                    is_nullable = c("NO", "YES"))

  fn <- build(tab)

  country <- fn(c(1L, 2L), c("AFG", "AGH"))
  expect_equal(country$id, c(1L, 2L))
  expect_equal(country$name, c("AFG", "AGH"))
})

test_that("functions handle type checking", {
  tab <- data.frame(table_name = "country",
                    column_name = c("id", "name"),
                    r_type = c("integer", "character"),
                    is_nullable = c("NO", "YES"))

  fn <- build(tab)

  valid_id_and_name <- fn(1L, "AFG")
  expect_equal(valid_id_and_name$id, 1L)
  expect_equal(valid_id_and_name$name, "AFG")

  no_name <- fn(2L)
  expect_equal(no_name$id, 2L)
  expect_true(is.na(no_name$name))

  expect_error(fn(), "argument \"id\" is missing, with no default")
  expect_error(fn(NA_integer_), "NA values found in 'id', but it is not nullable", fixed = TRUE)
  expect_error(fn("AFG"), "Expected 'id' to be of type 'integer' (but was 'character')", fixed = TRUE)
  expect_error(fn(1L, 123), "Expected 'name' to be of type 'character' (but was 'double')", fixed = TRUE)
})
