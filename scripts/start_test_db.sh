#!/usr/bin/env bash
set -e
docker run -d -p 5432:5432 \
  --name postgres-northwind \
  bradymholt/postgres-northwind:latest
