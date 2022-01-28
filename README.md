# Fakerbase <img src='man/figures/logo.png' align="right" height="138.5" />
[![codecov](https://codecov.io/gh/reside-ic/fakerbase/branch/master/graph/badge.svg?token=PSbEOyI1yi)](https://codecov.io/gh/reside-ic/fakerbase)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
![R-CMD-check](https://github.com/reside-ic/fakerbase/actions/workflows/R-CMD-check.yml/badge.svg)

Use case: unit testing code that manipulates data frames obtained by querying a Postgres database. Auto-generate functions for 
creating in memory data frames that mirror the structure of the database, for easy mocking of the tables. 

**Note that for now this only supports Postgres databases with the following types: "integer", "smallint", "boolean", "numeric", "real", "date", "timestamp without time zone", "timestamp with time zone"**

## Usage

1. Create a db connection. To start a dockerised Postgres database containing the Northwind sample database using [this image](https://github.com/bradymholt/docker-postgresql-northwind), run `./scripts/start_test_db.sh`. 
Then you can use the following connection:

```{r}
    con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "northwind",
                        host = "localhost",
                        user = "northwind",
                        password = "northwind")
```

2. Generate and load functions for creating fake db tables

```{r}    
    db <- fakerbase::fb_generate(con, schema_name = "public")
```

3. Use generated functions to create fake db tables

```{r}
    region <- db$region(region_id = 123L, region_description = "Central America")
    str(region)
    'data.frame':	1 obs. of  2 variables:
     $ region_id  : int 123
     $ region_description: chr "Central America"
```

4. To re-use generated functions without re-connecting to the database, use

```{r}
    db <- fakerbase::fb_load("northwind", schema_name = "public")
```

## Testing

If running integration tests, first run `./scripts/start_test_db.sh` which starts a Postgres instance running in a
docker container (using host networking.) To remove the test database, run `./scripts/stop_test_db.sh`.
