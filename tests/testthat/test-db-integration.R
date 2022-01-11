test_that("can generate functions from db", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "postgres",
                        host = "localhost",
                        port = 5432,
                        password = "password",
                        user = "postgres")

  generate_mocks(con, "pg_catalog", "tests")
  expect_error(parse(file.path("tests/inst/fakerbase/generated.R")), NA)
})
