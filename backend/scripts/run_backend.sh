#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if [[ -f "backend/.env" ]]; then
  set -a
  source "backend/.env"
  set +a
fi

if [[ ! -x ".venv312/bin/uvicorn" ]]; then
  echo "Missing .venv312 with backend dependencies."
  echo "Create it with:"
  echo "  python3.12 -m venv .venv312"
  echo "  .venv312/bin/pip install -r backend/requirements.txt"
  exit 1
fi

exec .venv312/bin/uvicorn backend.app.main:app --reload --host 0.0.0.0 --port "${PORT:-8000}"
