int_types <- c("integer", "smallint")
logi_types <- c("boolean")
num_types <- c("numeric", "real")
date_types <- c("date", "timestamp without time zone", "timestamp with time zone")

validate <- function(x, r_type, nullable) {
  name <- deparse(substitute(x))
  if (r_type %in% date_types) {
    if (!inherits(x, r_type)) {
      stop(sprintf("Expected '%s' to be of type '%s' (but was '%s')", name, r_type, typeof(x)), call. = FALSE)
    }
  }
  else {
    if (typeof(x) != r_type) {
      stop(sprintf("Expected '%s' to be of type '%s' (but was '%s')", name, r_type, typeof(x)), call. = FALSE)
    }
  }
  if (!nullable && any(is.na(x))) {
    stop(sprintf("NA values found in '%s', but it is not nullable", name), call. = FALSE)
  }
}

build <- function(table, env = asNamespace("fakerbase")) {
  args <- do.call(build_args, table)
  names(args) <- table$column_name
  cols <- lapply(table$column_name, as.name)
  names(cols) <- table$column_name
  expr <- as.call(c(list(quote(data.frame)),
                    cols,
                    list(stringsAsFactors = FALSE)))

  body <- c(
    Map(function(col_name, is_nullable, r_type) {
      env <- list(x = as.name(col_name), y = r_type, z = is_nullable == "YES")
      substitute_(quote(validate(x, y, z)), env)
    }, table$column_name, table$is_nullable, table$r_type),
    list(expr))

  as_function(args, body, env)
}

build_args <- function(is_nullable, r_type, ...) {
  res <- rep(alist(. =), length(is_nullable))
  res[is_nullable == "YES" & r_type == "integer"] <- alist(. = NA_integer_)
  res[is_nullable == "YES" & r_type == "numeric"] <- alist(. = NA_real_)
  res[is_nullable == "YES" & r_type == "character"] <- alist(. = NA_character_)
  res[is_nullable == "YES" & r_type == "logical"] <- alist(. = NA)
  res[is_nullable == "YES" & r_type == "POSIXct"] <- alist(. = NA_real_)
  res
}

substitute_ <- function(expr, env) {
  eval(substitute(substitute(y, env), list(y = expr)))
}

as_function <- function(args, body, env) {
  body_expr <- list(as.call(c(list(as.name("{")), unname(body))))
  as.function(c(args, body_expr), env)
}

tables_with_types <- function(tables) {
  tables$r_type <- "character"
  tables[tables$data_type %in% int_types, "r_type"] <- "integer"
  tables[tables$data_type %in% logi_types, "r_type"] <- "logical"
  tables[tables$data_type %in% num_types, "r_type"] <- "double"
  tables[tables$data_type %in% date_types, "r_type"] <- "POSIXct"
  split(tables, tables$table_name)
}

fetch_tables <- function(con, schema_name) {
  safe_param <- DBI::dbQuoteLiteral(con, schema_name)
  query <- paste0("SELECT column_name, table_name, data_type, column_default, is_nullable FROM
  information_schema.columns WHERE table_schema = ", safe_param)
  DBI::dbGetQuery(con, query)
}

#' Generate mocking functions for all tables in the given db schema
#'
#' @param con DBI connection
#' @param package_path (optional) path to package root in which to generate functions
#' @param path (options) path to directory in which to generate functions.
#' Will only apply if not using package_path argument
#' @param schema_name name of the db schema
#' @returns list of named functions corresponding to the tables in the schema
#' @export
fb_generate <- function(con, package_path = NULL, path = ".", schema_name = "public") {
  dbname <- DBI::dbGetInfo(con)$dbname
  if (!is.null(package_path)) {
    desc <- file.path(package_path, "DESCRIPTION")
    if (!file.exists(desc)) {
      stop("Did not find package at ", package_path)
    }
    dest <- file.path(package_path, "inst", "fakerbase", dbname, schema_name)
  } else {
    dest <- file.path(path, "fakerbase", dbname, schema_name)
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  tables <-
    tables_with_types(tables = fetch_tables(con, schema_name))
  fns <- lapply(tables, build)
  saveRDS(fns, file.path(dest, "generated.rds"))
  fns
}

#' Load previously generated mocking functions for all tables in the given db and schema
#'
#' @param dbname name of the database
#' @param package (optional) name of the package for which functions have been generated
#' @param path (optional) absolute path where functions where generated.
#' Only used if package argument is not provided.
#' @param schema_name name of the db schema
#' @returns list of named functions corresponding to the tables in the schema
#' @export
fb_load <- function(dbname, package = NULL, path = ".", schema_name = "public") {
  if (!is.null(package)) {
    db_dir <- system.file("fakerbase", dbname, package = package)
    detail <- sprintf("for package %s", package)
  } else {
    db_dir <- file.path(path, "fakerbase", dbname)
    detail <- sprintf("at path %s", path)
  }
  if (!dir.exists(db_dir)) {
    e <- "Functions for database '%s' have not been generated %s. See fakerbase::fb_generate"
    stop(sprintf(e, dbname, detail), call. = FALSE)
  }
  schema_dir <- file.path(db_dir, schema_name)
  if (!dir.exists(schema_dir)) {
    e <- "Functions for schema '%s' have not been generated %s. See fakerbase::fb_generate"
    stop(sprintf(e, schema_name, detail), call. = FALSE)
  }
  generated <- file.path(schema_dir, "generated.rds")
  readRDS(generated)
}
