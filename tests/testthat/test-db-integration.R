test_that("can generate functions from db", {
  con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "northwind",
                        host = "localhost",
                        port = 5432,
                        password = "northwind",
                        user = "northwind")

  db <- generate(con, "public")
  fake_categories <- db$categories(category_id = 1L, category_name = "test cat")
  expect_equal(fake_categories$category_id, 1L)
  expect_equal(fake_categories$category_name, "test cat")
  expect_true(is.na(fake_categories$description))
  expect_true(is.na(fake_categories$picture))

  fake_region <- db$region(region_id = c(1L, 2L), region_description = c("region 1", "region 2"))
  expect_equal(fake_region$region_id, c(1L, 2L))
  expect_equal(fake_region$region_description, c("region 1", "region 2"))
})
