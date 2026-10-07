#!/bin/sh
# Osobna rola i baza dla LiteLLM (nie mieszamy jej z bazą aplikacji).
# Skrypty z docker-entrypoint-initdb.d wykonują się tylko przy pierwszym starcie na pustym wolumenie.
set -e

psql -v ON_ERROR_STOP=1 -v pw="$LITELLM_DB_PASSWORD" --username "$POSTGRES_USER" --dbname postgres <<'SQL'
CREATE ROLE litellm LOGIN PASSWORD :'pw';
CREATE DATABASE litellm OWNER litellm;
SQL
