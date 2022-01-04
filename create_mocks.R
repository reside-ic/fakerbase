con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "montagu",
                      host = "localhost",
                      user = "montagu",
                      password = "montagu")


generate_mocks <- function(con, schema_name) {
  safe_param <- DBI::dbQuoteLiteral(con, schema_name)
  file_con <- file("generated.R")
  on.exit(close(file_con))
  mocks <- writeLines(DBI::dbGetQuery(con, paste0("select create_mock_schema(", safe_param, ");"))[[1]], file_con)
}

generate_mocks(con, "public")
