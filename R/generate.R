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

generate_fake_table_function <- function(table) {
  ret <- paste0("fake_", table$table_name[[1]], " <- function(")
  args <- paste0(table$column_name, ifelse(table$is_nullable == "YES", " = NA", ""), collapse = ", ")
  dat <- paste(table$column_name, "=", table$column_name, collapse = ", ")
  ret <- paste0(ret, args, ") {\n ")
  type_checks <- paste0(table$type_check, collapse = "\n  ")
  ret <- paste(ret, type_checks)
  ret <- paste0(ret, "\n  data.frame(", dat, ")\n}")
  ret
}

generate_functions <- function(tables) {
  tables$type_check <- generate_type_check(tables$column_name, tables$data_type, tables$is_nullable)
  tables <- split(tables, tables$table_name)
  sapply(tables, generate_fake_table_function)
}

get_tables <- function(con, schema_name) {
  safe_param <- DBI::dbQuoteLiteral(con, schema_name)
  query <- paste0("SELECT column_name, table_name, data_type, column_default, is_nullable FROM
  information_schema.columns WHERE table_schema = ", safe_param)
  DBI::dbGetQuery(con, query)
}

#' Generate file containing mocking functions for all tables in the given db schema
#'
#' @param con DBI connection
#' @param schema_name name of the db schema
#' @param path path to the directory where the mocks should be generated
#' @export
generate <- function(con, schema_name, path) {
  dest <- file.path(path, "inst/fakerbase")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  tables <- get_tables(con, schema_name)
  mocks <- generate_functions(tables)
  writeLines(mocks, file.path(dest, "generated.R"))
}