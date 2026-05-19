#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"
npm install

python3 -m venv services/api/.venv
services/api/.venv/bin/python -m pip install --upgrade pip
services/api/.venv/bin/python -m pip install -r services/api/requirements.txt

echo "Application dependencies installed."
