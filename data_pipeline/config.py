"""
config.py — Configuration centrale du data_pipeline.

Charge les variables depuis le fichier .env à la racine du projet.
Tous les autres modules importent depuis ici, jamais directement depuis os.environ.
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Remonte d'un niveau pour trouver le .env à la racine du monorepo
ROOT_DIR = Path(__file__).parent.parent
load_dotenv(ROOT_DIR / ".env")

# ── TMDb ────────────────────────────────────────────────────────────────────────
TMDB_API_KEY: str = os.getenv("TMDB_API_KEY", "")
TMDB_BASE_URL: str = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE_URL: str = "https://image.tmdb.org/t/p"

# ── Gemini ──────────────────────────────────────────────────────────────────────
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

# ── Chemins locaux ──────────────────────────────────────────────────────────────
DATA_DIR = ROOT_DIR / "data_pipeline" / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

# ── Validation au démarrage ─────────────────────────────────────────────────────
if not TMDB_API_KEY:
    raise EnvironmentError(
        "❌ TMDB_API_KEY manquante.\n"
        "   → Copie .env.example en .env et remplis ta clé TMDb."
    )
