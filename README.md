# CineBook 🎬

> Plateforme de recommandation de films basée sur l'atmosphère, l'esthétique visuelle, la bande-son, le rythme et les thèmes.

## Structure du projet (Monorepo)

```
CineBook/
├── data_pipeline/   # Scripts Python : extraction de données, couleurs, LLM
├── backend/         # API FastAPI + SQLite
└── frontend/        # Application Next.js (TypeScript + Tailwind)
```

## Démarrage rapide

```bash
# 1. Copier les variables d'environnement
cp .env.example .env
# → Remplis TMDB_API_KEY dans .env

# 2. Créer et activer le virtual environment Python
python -m venv .venv
.venv\Scripts\activate      # Windows
# source .venv/bin/activate  # macOS/Linux

# 3. Installer les dépendances du pipeline
pip install -r data_pipeline/requirements.txt

# 4. Tester la connexion TMDb
python data_pipeline/test_tmdb.py
```

## Stack Technique

| Couche | Technologies |
|---|---|
| Data Pipeline | Python 3.12, Pillow, NumPy, google-genai |
| Backend | Python 3.12, FastAPI, SQLAlchemy, SQLite |
| Frontend | Next.js 14 (App Router), TypeScript, Tailwind CSS |
