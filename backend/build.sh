#!/usr/bin/env bash
# build.sh — Script de build pour Render (Environnement Python)
set -o errexit

echo "🚀 Installation des dépendances Backend..."
pip install --upgrade pip
if [ -f "backend/requirements.txt" ]; then
  pip install -r backend/requirements.txt
elif [ -f "requirements.txt" ]; then
  pip install -r requirements.txt
fi

echo "🎬 Peuplement de la base SQLite avec les 142 films..."
if [ -f "seed_db.py" ]; then
  python seed_db.py
else
  python -m backend.seed_db
fi

echo "✅ Build Backend Render terminé avec succès !"
