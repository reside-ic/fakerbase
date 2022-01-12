#!/usr/bin/env bash
set -e
docker run --name test-db \
 --network host \
 -e POSTGRES_PASSWORD=password \
 -e PGPASSWORD=password \
  -d postgres

RETRIES=5

until psql -h localhost -U postgres -d postgres -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 1
done

docker exec test-db psql -U postgres -d postgres -c "CREATE USER test WITH PASSWORD 'password';"
