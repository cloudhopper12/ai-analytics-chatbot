#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_ENV_FILE="${ROOT_DIR}/services/api/.env"
WEB_ENV_FILE="${ROOT_DIR}/apps/web/.env.local"

DB_NAME="${DB_NAME:-analytics_chatbot}"
APP_DB_USER="${APP_DB_USER:-analytics_app}"
ANALYTICS_DB_USER="${ANALYTICS_DB_USER:-analytics_readonly}"
REMOTE_HOST="${REMOTE_HOST:-localhost}"

if [ -f "${API_ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${API_ENV_FILE}"
  set +a
fi

random_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
  else
    python3 -c 'import secrets; print(secrets.token_hex(24))'
  fi
}

APP_DB_PASSWORD="${APP_DB_PASSWORD:-$(random_password)}"
ANALYTICS_DB_PASSWORD="${ANALYTICS_DB_PASSWORD:-$(random_password)}"
WEB_ORIGIN="${WEB_ORIGIN:-http://${REMOTE_HOST}:3000}"
NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://${REMOTE_HOST}:8000}"
APP_DATABASE_URL="postgresql://${APP_DB_USER}:${APP_DB_PASSWORD}@localhost:5432/${DB_NAME}"
ANALYTICS_DATABASE_URL="postgresql://${ANALYTICS_DB_USER}:${ANALYTICS_DB_PASSWORD}@localhost:5432/${DB_NAME}"

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

mkdir -p "$(dirname "${API_ENV_FILE}")" "$(dirname "${WEB_ENV_FILE}")"
cat > "${API_ENV_FILE}" <<ENV
APP_DB_PASSWORD=${APP_DB_PASSWORD}
ANALYTICS_DB_PASSWORD=${ANALYTICS_DB_PASSWORD}
APP_DATABASE_URL=${APP_DATABASE_URL}
ANALYTICS_DATABASE_URL=${ANALYTICS_DATABASE_URL}
WEB_ORIGIN=${WEB_ORIGIN}
MAX_QUERY_ROWS=${MAX_QUERY_ROWS:-500}
STATEMENT_TIMEOUT_MS=${STATEMENT_TIMEOUT_MS:-5000}
ENV
chmod 600 "${API_ENV_FILE}"

cat > "${WEB_ENV_FILE}" <<ENV
NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV
chmod 600 "${WEB_ENV_FILE}"

echo "Database ${DB_NAME} is ready."
echo "Wrote local API config to ${API_ENV_FILE}."
echo "Wrote local web config to ${WEB_ENV_FILE}."
