#!/bin/bash

podman run -d \
  --name service-db \
  -e POSTGRES_USER=sb \
  -e POSTGRES_PASSWORD=sb \
  -e POSTGRES_DB=db \
  -p 5432:5432 \
  -v $PWD/init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  docker.io/postgres:14
