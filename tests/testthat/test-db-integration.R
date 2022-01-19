test_that("can generate and load from db", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "northwind",
                        host = "localhost",
                        port = 5432,
                        password = "northwind",
                        user = "northwind")

  db <- fb_generate(con, ".", "public")
  fake_categories <- db$categories(category_id = 1L, category_name = "test cat")
  expect_equal(fake_categories$category_id, 1L)
  expect_equal(fake_categories$category_name, "test cat")
  expect_true(is.na(fake_categories$description))
  expect_true(is.na(fake_categories$picture))

  fake_region <- db$region(region_id = c(1L, 2L), region_description = c("region 1", "region 2"))
  expect_equal(fake_region$region_id, c(1L, 2L))
  expect_equal(fake_region$region_description, c("region 1", "region 2"))
})

test_that("can load without db connection", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "northwind",
                        host = "localhost",
                        port = 5432,
                        password = "northwind",
                        user = "northwind")

  generated <- fb_generate(con, ".", "public")
  loaded <- fb_load("northwind", ".", "public")
  expect_equal(generated, loaded)
})

test_that("loading un-generated functions gives descriptive error message", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "northwind",
                        host = "localhost",
                        port = 5432,
                        password = "northwind",
                        user = "northwind")

  generated <- fb_generate(con, ".", "public")
  expect_error(fb_load("baddbname", ".", "public"), "Functions for database 'baddbname' have not been generated yet. See fakerbase::generate")
  expect_error(fb_load("northwind", ".", "badschemaname"), "Functions for schema 'badschemaname' have not been generated yet. See fakerbase::generate")
})
