To see the basic concept working:
1. run a copy of [montagu-db](https://github.com/vimc/montagu-db): `./montagu-db/scripts/start.sh master 5432`
2. you'll also need to add a user: `docker exec -it db psql -U postgres -d montagu -c "CREATE USER montagu WITH PASSWORD 'montagu'; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO montagu;"`
3. create the sql functions: `psql -h localhost -U montagu -d montagu -f create_mock_table.sql -f create_mock_schema.sql` (enter password "montagu" when prompted)
4. run `create_mocks.R` to generate a file called `generated.R` containing functions for creating mock tables
