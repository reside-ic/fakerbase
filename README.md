# Proof of basic concept

1. run a copy of [montagu-db](https://github.com/vimc/montagu-db): `./montagu-db/scripts/start.sh master 5432`
2. you'll also need to add a user: `docker exec -it db psql -U postgres -d montagu -c "CREATE USER montagu WITH PASSWORD 'montagu'; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO montagu;"`
3. create the sql functions: `psql -h localhost -U montagu -d montagu -f create_mock_table.sql -f create_mock_schema.sql` (enter password "montagu" when prompted)
4. run `create_mocks.R` to generate a file called `generated.R` containing functions for creating mock tables

# Musts

1. Use a config file containing db config, inc schema name to generate mocks for
2. Have single script that executes the whole process
     1. do we actually want to create functions, or is it better to just execute the SQL as a one off? it'd be nicer to do the latter so that the db user only requires read permissions
    2.  can we do this without requiring psql? it seemed suprisingly hard to just execute a SQL script from R
3. Turn this into a package

# Coulds

1. Do type checking within the generated methods, based on the SQL types

# Think about use protocol

1. Should this tool be re-run during CI, or every time a test suite is run, as a way of making sure tests fail when db changes? Or just rely on manual re-running when db is known to have changed?
