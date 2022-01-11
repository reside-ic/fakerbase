# Usage

```{r}
    # create a db connection
    con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "montagu",
                        host = "localhost",
                        user = "montagu",
                        password = "montagu")
    
    # generate mocks into ./inst/fakerbase/generated.R
    fakerbase::generate(con, "public", ".")
```

# Testing

If running integration tests, first run `./scripts/start_test_db.sh` which starts 
a Postgres instance running in a docker container (using host networking.) To remove the 
test database, run `./scripts/stop_test_db.sh`.
