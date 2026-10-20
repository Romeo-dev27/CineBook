#!/usr/bin/env bash
# build.sh — Script de build pour Render (Environnement Python)
set -o errexit

echo "🚀 Installation des dépendances Backend..."
pip install --upgrade pip
pip install -r backend/requirements.txt

echo "🎬 Peuplement de la base SQLite avec les 142 films..."
python -m backend.seed_db

echo "✅ Build Backend Render terminé avec succès !"
