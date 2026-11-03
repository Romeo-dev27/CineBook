"""
movies.py — Routes de consultation des films, des genres et des tags
"""

import unicodedata
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from database import get_db
from models import Movie, Genre, AtmosphereTag
from schemas import MovieBriefOut, MovieDetailOut, GenreOut, AtmosphereTagOut, WatchProviderOut
from watch_providers_service import watch_providers_service

router = APIRouter(prefix="/api", tags=["Films & Filtres"])


def _strip_accents(text: str) -> str:
    return "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    ).lower().strip()


@router.get("/genres", response_model=List[GenreOut], summary="Liste de tous les genres")
def get_genres(db: Session = Depends(get_db)):
    """Retourne la liste des genres disponibles pour alimenter les listes déroulantes de Flutter."""
    return db.query(Genre).order_by(Genre.name).all()


@router.get("/tags", response_model=List[AtmosphereTagOut], summary="Liste des 20 tags d'atmosphère")
def get_atmosphere_tags(db: Session = Depends(get_db)):
    """Retourne les 20 dimensions d'atmosphère de CineBook."""
    return db.query(AtmosphereTag).order_by(AtmosphereTag.name).all()


@router.get("/movies", response_model=List[MovieBriefOut], summary="Recherche et liste des films")
def get_movies(
    query: Optional[str] = Query(None, description="Recherche par titre (insensible aux accents et à la casse)"),
    genre: Optional[str] = Query(None, description="Filtre par nom de genre exact (ex: Drama, Sci-Fi)"),
    tag: Optional[str] = Query(None, description="Filtre par tag d'atmosphère (ex: melancholic, tense)"),
    skip: int = Query(0, ge=0, description="Décalage pour pagination"),
    limit: int = Query(50, ge=1, le=150, description="Nombre max de résultats"),
    db: Session = Depends(get_db),
):
    """
    Recherche dynamique de films avec filtres combinables :
    - Titre partiel
    - Genre spécifique
    - Tag d'atmosphère
    """
    q = db.query(Movie)

    if genre:
        q = q.join(Movie.genres).filter(Genre.name.ilike(f"%{genre}%"))

    if tag:
        q = q.join(Movie.atmosphere_tags).filter(AtmosphereTag.name.ilike(f"%{tag}%"))

    movies = q.all()

    # Filtrage par titre insensible aux accents en mémoire Python
    if query:
        norm_query = _strip_accents(query)
        movies = [m for m in movies if norm_query in _strip_accents(m.title)]

    # Pagination
    paginated = movies[skip : skip + limit]

    # Sérialisation propre avec plateformes de streaming
    return [
        MovieBriefOut(
            id=m.id,
            title=m.title,
            year=m.year,
            poster_path=m.poster_path,
            backdrop_path=m.backdrop_path,
            vote_average=m.vote_average,
            vote_count=m.vote_count,
            pacing=m.pacing,
            genres=[g.name for g in m.genres],
            atmosphere_tags=[t.name for t in m.atmosphere_tags],
            streaming_providers=[
                WatchProviderOut(**p) for p in watch_providers_service.get_providers_for_movie(m.id)
            ]
        )
        for m in paginated
    ]


@router.get("/movies/{movie_id}", response_model=MovieDetailOut, summary="Détails complets d'un film")
def get_movie_detail(movie_id: int, db: Session = Depends(get_db)):
    """Retourne toutes les métadonnées d'un film, y compris sa palette de couleurs (Vector 3)."""
    movie = db.query(Movie).filter(Movie.id == movie_id).first()
    if not movie:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Film avec l'ID {movie_id} introuvable."
        )

    palette_out = None
    if movie.color_palette:
        p = movie.color_palette
        palette_out = {
            "warmth": p.warmth,
            "coolness": p.coolness,
            "avg_brightness": p.avg_brightness,
            "avg_saturation": p.avg_saturation,
            "contrast": p.contrast,
            "colorfulness": p.colorfulness,
            "darkness_ratio": p.darkness_ratio,
            "vividness_ratio": p.vividness_ratio,
            "teal_ratio": p.teal_ratio,
            "orange_ratio": p.orange_ratio,
        }

    detail_providers = [
        WatchProviderOut(**p) for p in watch_providers_service.get_providers_for_movie(movie.id)
    ]

    return MovieDetailOut(
        id=movie.id,
        title=movie.title,
        original_title=movie.original_title,
        year=movie.year,
        overview=movie.overview,
        poster_path=movie.poster_path,
        backdrop_path=movie.backdrop_path,
        vote_average=movie.vote_average,
        vote_count=movie.vote_count,
        popularity=movie.popularity,
        pacing=movie.pacing,
        genres=[g.name for g in movie.genres],
        atmosphere_tags=[t.name for t in movie.atmosphere_tags],
        color_palette=palette_out,
        streaming_providers=detail_providers
    )


@router.get("/movies/{movie_id}/providers", response_model=List[WatchProviderOut], summary="Plateformes de streaming d'un film")
def get_movie_streaming_providers(
    movie_id: int,
    country: str = Query("FR", description="Code pays ISO 3166-1 (défaut : FR)"),
    db: Session = Depends(get_db)
):
    """Retourne la liste des plateformes de streaming (SVOD) où le film est disponible."""
    movie = db.query(Movie).filter(Movie.id == movie_id).first()
    if not movie:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Film avec l'ID {movie_id} introuvable."
        )

    providers = watch_providers_service.get_providers_for_movie(movie_id, country=country)
    return [WatchProviderOut(**p) for p in providers]
