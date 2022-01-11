# Usage

1. Create a db connection

```{r}
    con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "montagu",
                        host = "localhost",
                        user = "montagu",
                        password = "montagu")
```

2. Generate and load functions for creating fake db tables

```{r}    
    fakerbase::generate(con, "public", ".")
```

3. Use generated functions to create fake db tables

```{r}
    country <- fake_country(id = "AFG", name = "Afghanistan", nid = 123L)
    str(country)
    'data.frame':	1 obs. of  3 variables:
     $ id  : chr "AFG"
     $ name: chr "Afghanistan"
     $ nid : int 123
```

# Testing

If running integration tests, first run `./scripts/start_test_db.sh` which starts a Postgres instance running in a
docker container (using host networking.) To remove the test database, run `./scripts/stop_test_db.sh`.
