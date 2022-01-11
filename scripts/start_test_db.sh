#!/usr/bin/env bash
set -e
docker run --name test-db \
 --network host \
 -e POSTGRES_PASSWORD=password \
 -e PGPASSWORD=password \
  -d postgres
