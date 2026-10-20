#!/usr/bin/env bash
# start.sh — Script de démarrage du serveur FastAPI sur Render
set -o errexit

PORT=${PORT:-8000}
echo "🚀 Démarrage de CineBook API sur le port $PORT..."
exec uvicorn backend.main:app --host 0.0.0.0 --port "$PORT" --workers 2
