#!/usr/bin/env bash
# start.sh — Script de démarrage du serveur FastAPI sur Render
set -o errexit

PORT=${PORT:-8000}
echo "🚀 Démarrage de CineBook API sur le port $PORT..."
if [ -f "main.py" ]; then
  python -c "from seed_db import seed_if_empty; seed_if_empty()"
  exec uvicorn main:app --host 0.0.0.0 --port "$PORT" --workers 2
else
  python -c "from backend.seed_db import seed_if_empty; seed_if_empty()"
  exec uvicorn backend.main:app --host 0.0.0.0 --port "$PORT" --workers 2
fi
