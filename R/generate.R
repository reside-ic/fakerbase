int_types <- c("integer", "smallint")
logi_types <- c("boolean")
num_types <- c("numeric", "real")
date_types <- c("date", "timestamp without time zone", "timestamp with time zone")

validate_type <- quote(stopifnot(typeof(x) == y))
validate_inherits <- quote(stopifnot(inherits(x, y)))
validate_nulls <- quote(stopifnot(!any(is.na(x))))

build <- function(table, env = topenv()) {
  args <- do.call(build_args, table)
  names(args) <- table$column_name
  cols <- lapply(table$column_name, as.name)
  names(cols) <- table$column_name
  expr <- as.call(c(list(quote(data.frame)),
                    cols,
                    list(stringsAsFactors = FALSE)))

  body <- c(
    unlist(Map(function(col_name, is_nullable, r_type) {
      env <- list(x = as.name(col_name), y = r_type)
      c(if (r_type == "POSIXct") substitute_(validate_inherits, env),
        if (r_type != "POSIXct") substitute_(validate_type, env),
        if (is_nullable == "NO") substitute_(validate_nulls, env))
    },
               table$column_name, table$is_nullable, table$r_type)),
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

generate <- function(con, schema = "public", path = ".") {
  dest <- file.path(path, "inst/fakerbase")
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  tables <- tables_with_types(tables <- fetch_tables(con, schema))
  lapply(tables, build)
}
