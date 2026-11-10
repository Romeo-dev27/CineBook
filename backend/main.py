"""
main.py — Point d'entrée de l'application FastAPI CineBook

Configure :
- L'instance FastAPI avec métadonnées complètes
- Le middleware CORS pour autoriser Flutter Web & Mobile
- L'inclusion des routeurs REST (/api/movies, /api/recommend)
- Les endpoints de statut et santé (/ et /health)
"""

import os
import sys
from pathlib import Path

# Assure l'import direct des modules locaux quand Render définit Root Directory sur 'backend'
_backend_dir = str(Path(__file__).resolve().parent)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import engine, get_db, Base, SessionLocal
from models import Movie
from seed_db import seed_if_empty
from routes.movies import router as movies_router
from routes.recommend import router as recommend_router
from routes.auth import router as auth_router
from routes.watchlist import router as watchlist_router

# Assurer la création des tables si la DB n'existe pas encore (y compris users et watchlist_items)
Base.metadata.create_all(bind=engine)

# Filet de sécurité Render free : le filesystem est éphémère, la base peut revenir
# vide après une mise en veille. start.sh le fait déjà une fois avant les workers ;
# ici on couvre le cas d'une Start Command qui lancerait uvicorn directement.
try:
    seed_if_empty()
except Exception:
    # Course possible entre les 2 workers : celui qui perd voit des doublons,
    # mais l'autre a commité une base correcte.
    _db = SessionLocal()
    try:
        if _db.query(Movie).count() == 0:
            raise
    finally:
        _db.close()

app = FastAPI(
    title="CineBook API",
    description=(
        "API REST cinématographique pour la recommandation de films par Similarité "
        "Cosinus Pondérée (Ambiance, Esthétique Visuelle, Rythme, Genre, Époque) "
        "avec modificateur de découverte et gestion de comptes utilisateurs."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# ── Middleware CORS (Essentiel pour Flutter Web / Mobile) ──────────────────────
# L'auth se fait par en-tête Bearer, jamais par cookie : allow_credentials doit
# rester faux, sinon Starlette échoit n'importe quelle origine sur des requêtes
# authentifiées.
_cors_origins = [o.strip() for o in os.getenv("CORS_ALLOW_ORIGINS", "").split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routeurs ──────────────────────────────────────────────────────────────────
app.include_router(movies_router)
app.include_router(recommend_router)
app.include_router(auth_router)
app.include_router(watchlist_router)



# ── Diagnostics & Santé ───────────────────────────────────────────────────────
@app.get("/", tags=["Système"], summary="Accueil de l'API")
def root():
    return {
        "message": "Bienvenue sur l'API CineBook 🎬",
        "version": "1.0.0",
        "docs": "/docs",
        "endpoints": {
            "movies": "/api/movies",
            "genres": "/api/genres",
            "tags": "/api/tags",
            "recommend": "/api/recommend"
        }
    }


@app.get("/health", tags=["Système"], summary="Vérification de l'état du serveur et de la base")
def health_check(db: Session = Depends(get_db)):
    # Vérification de la connectivité SQLite
    db.execute(text("SELECT 1"))
    movie_count = db.query(Movie).count()

    return {
        "status": "healthy",
        "database": "connected",
        "indexed_movies": movie_count,
    }
