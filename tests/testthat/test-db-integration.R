test_that("can generate functions from db", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "postgres",
                        host = "localhost",
                        port = 5432,
                        password = "password",
                        user = "postgres")

  expect_error(generate(con, "pg_catalog", "tests"), NA)
  expect_true(file.exists("tests/inst/fakerbase/generated.R"))
})
