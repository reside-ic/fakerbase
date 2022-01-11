con <- DBI::dbConnect(RPostgres::Postgres(),
                      dbname = "montagu",
                      host = "localhost",
                      user = "montagu",
                      password = "montagu")

int_types <- c("integer", "smallint")
logi_types <- c("boolean")
num_types <- c("date", "numeric", "real")
date_types <- c("timestamp without time zone", "timestamp with time zone")

generate_type_check <- function(column_name, data_type, is_nullable) {
  r_type <- ifelse(data_type %in% int_types, "\"integer\"",
                   ifelse(data_type %in% logi_types, "\"logical\"",
                          ifelse(data_type %in% num_types, "\"double\"", "\"character\"")))

  type_check <- paste0("typeof(", column_name, ") == ", r_type)
  type_check <- ifelse(data_type %in% date_types, paste0("inherits(", column_name, ", \"POSIXct\")"), type_check)

  na_check <- ifelse(is_nullable == "YES", paste0("is.na(", column_name, ") || "), "")
  paste0("stopifnot(", na_check, type_check, ")")
}

get_tables <- function(con, schema_name) {
  safe_param <- DBI::dbQuoteLiteral(con, schema_name)
  query <- paste0("SELECT column_name, table_name, data_type, column_default, is_nullable FROM
  information_schema.columns WHERE table_schema = ", safe_param)
  tables <- DBI::dbGetQuery(con, query)
  tables$type_check <- generate_type_check(tables$column_name, tables$data_type, tables$is_nullable)
  split(tables, tables$table_name)
}

generate_mock_table <- function(table) {
  ret <- paste0("mock_", table$table_name[[1]], " <- function(")
  args <- paste0(table$column_name, ifelse(table$is_nullable == "YES", " = NA", ""), collapse = ", ")
  dat <- paste(table$column_name, "=", table$column_name, collapse = ", ")
  ret <- paste0(ret, args, ") {\n ")
  type_checks <- paste0(table$type_check, collapse = "\n  ")
  ret <- paste(ret, type_checks)
  ret <- paste0(ret, "\n  data.frame(", dat, ")\n}")
  ret
}

generate_mocks <- function(con, schema_name) {
  tables <- get_tables(con, schema_name)
  file_con <- file("generated.R")
  on.exit(close(file_con))
  mocks <- sapply(tables, generate_mock_table)
  writeLines(mocks, file_con)
}

generate_mocks(con, "public")
