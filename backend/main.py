"""
main.py — Point d'entrée de l'application FastAPI CineBook

Configure :
- L'instance FastAPI avec métadonnées complètes
- Le middleware CORS pour autoriser Flutter Web & Mobile
- L'inclusion des routeurs REST (/api/movies, /api/recommend)
- Les endpoints de statut et santé (/ et /health)
"""

from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from backend.database import engine, get_db, Base
from backend.models import Movie
from backend.routes.movies import router as movies_router
from backend.routes.recommend import router as recommend_router

# Assurer la création des tables si la DB n'existe pas encore
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="CineBook API",
    description=(
        "API REST cinématographique pour la recommandation de films par Similarité "
        "Cosinus Pondérée (Ambiance, Esthétique Visuelle, Rythme, Genre, Époque) "
        "avec modificateur de découverte."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# ── Middleware CORS (Essentiel pour Flutter Web / Mobile) ──────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Autorise tous les domaines (idéal pour le dev Flutter Web/Mobile)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routeurs ──────────────────────────────────────────────────────────────────
app.include_router(movies_router)
app.include_router(recommend_router)


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
