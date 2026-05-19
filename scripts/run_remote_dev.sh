#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_NAME="${SESSION_NAME:-ai-analytics-chatbot}"
REMOTE_HOST="${REMOTE_HOST:-192.168.64.5}"

APP_DATABASE_URL="${APP_DATABASE_URL:-postgresql://analytics_app:analytics_app_password@localhost:5432/analytics_chatbot}"
ANALYTICS_DATABASE_URL="${ANALYTICS_DATABASE_URL:-postgresql://analytics_readonly:analytics_readonly_password@localhost:5432/analytics_chatbot}"
WEB_ORIGIN="${WEB_ORIGIN:-http://${REMOTE_HOST}:3000}"
NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-http://${REMOTE_HOST}:8000}"

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  tmux kill-session -t "${SESSION_NAME}"
fi

tmux new-session -d -s "${SESSION_NAME}" -n api -c "${ROOT_DIR}/services/api" \
  "source .venv/bin/activate && APP_DATABASE_URL='${APP_DATABASE_URL}' ANALYTICS_DATABASE_URL='${ANALYTICS_DATABASE_URL}' WEB_ORIGIN='${WEB_ORIGIN}' uvicorn app.main:app --host 0.0.0.0 --port 8000"

tmux new-window -t "${SESSION_NAME}" -n web -c "${ROOT_DIR}" \
  "NEXT_PUBLIC_API_URL='${NEXT_PUBLIC_API_URL}' npm run dev:web"

echo "Started tmux session: ${SESSION_NAME}"
echo "Web: ${WEB_ORIGIN}"
echo "API: ${NEXT_PUBLIC_API_URL}"
echo "Attach with: tmux attach -t ${SESSION_NAME}"
