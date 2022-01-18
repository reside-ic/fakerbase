int_types <- c("integer", "smallint")
logi_types <- c("boolean")
num_types <- c("numeric", "real")
date_types <- c("date", "timestamp without time zone", "timestamp with time zone")

validate <- function(x, r_type, nullable) {
  name <- deparse(substitute(x))
  if (r_type %in% date_types) {
    if (!inherits(x, r_type)) stop(sprintf("Expected '%s' to be of type '%s' (but was '%s')", name, r_type, typeof(x)),
                                   call. = FALSE)
  }
  else {
    if (typeof(x) != r_type) stop(sprintf("Expected '%s' to be of type '%s' (but was '%s')", name, r_type, typeof(x)),
                                  call. = FALSE)
  }
  if (!nullable && any(is.na(x))) stop(sprintf("NA values found in '%s', but it is not nullable", name),
                                       call. = FALSE)
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
#' @param schema_name name of the db schema
#' @returns list of named functions corresponding to the tables in the schema
#' @export
generate <- function(con, schema_name = "public") {
  tables <- tables_with_types(tables <- fetch_tables(con, schema_name))
  lapply(tables, build)
}
