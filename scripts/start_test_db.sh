#!/usr/bin/env bash
set -e
docker run -d -p 5432:5432 \
  --name postgres-northwind \
  bradymholt/postgres-northwind:latest

RETRIES=10

until PGPASSWORD=northwind psql -h localhost -U northwind -d northwind -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 1
done
