#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DB_NAME="${DB_NAME:-analytics_chatbot}"
APP_DB_USER="${APP_DB_USER:-analytics_app}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-analytics_app_password}"
ANALYTICS_DB_USER="${ANALYTICS_DB_USER:-analytics_readonly}"
ANALYTICS_DB_PASSWORD="${ANALYTICS_DB_PASSWORD:-analytics_readonly_password}"

sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_DB_USER}') THEN
    CREATE ROLE ${APP_DB_USER} LOGIN PASSWORD '${APP_DB_PASSWORD}';
  ELSE
    ALTER ROLE ${APP_DB_USER} WITH LOGIN PASSWORD '${APP_DB_PASSWORD}';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${ANALYTICS_DB_USER}') THEN
    CREATE ROLE ${ANALYTICS_DB_USER} LOGIN PASSWORD '${ANALYTICS_DB_PASSWORD}';
  ELSE
    ALTER ROLE ${ANALYTICS_DB_USER} WITH LOGIN PASSWORD '${ANALYTICS_DB_PASSWORD}';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME}' WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = '${DB_NAME}'
)\gexec
SQL

sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f "${ROOT_DIR}/database/schema.sql"
sudo -u postgres psql -v ON_ERROR_STOP=1 -d "${DB_NAME}" -f "${ROOT_DIR}/database/seed.sql"

echo "Database ${DB_NAME} is ready."
