#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-localhost}"

curl -fsS "http://${REMOTE_HOST}:8000/health"
echo
curl -fsS "http://${REMOTE_HOST}:3000" >/dev/null
echo "Remote web and API smoke tests passed."
