"""
recommend.py — Route POST /api/recommend pour le moteur de recommandation CineBook

Reçoit l'ID du film de référence, les pondérations des 5 vecteurs et
le curseur de découverte, puis renvoie les N films les plus similaires avec
leurs explications détaillées ("Pourquoi ce film ?").
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.database import get_db
from backend.models import Movie
from backend.schemas import (
    RecommendRequest,
    RecommendResponse,
    MovieBriefOut,
    RecommendationItem,
)
from backend.recommender_service import recommender_service

router = APIRouter(prefix="/api", tags=["Recommandations"])


@router.post(
    "/recommend",
    response_model=RecommendResponse,
    summary="Calculer les recommandations cinématographiques",
    description="Prend un film de référence, des pondérations (Ambiance, Visuel, Genre, Époque, Rythme) et un curseur de découverte pour retourner les meilleures recommandations expliquées."
)
def recommend_movies(
    req: RecommendRequest,
    db: Session = Depends(get_db)
):
    # 1. Vérifier l'existence du film de référence
    ref_movie = db.query(Movie).filter(Movie.id == req.movie_id).first()
    if not ref_movie:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Film de référence ID {req.movie_id} introuvable."
        )

    # 2. Convertir les poids Pydantic en dictionnaire pour le service
    weights_dict = req.weights.model_dump() if req.weights else None

    # 3. Calculer les recommandations via le service basé sur la base de données
    raw_results = recommender_service.recommend(
        db=db,
        reference_id=req.movie_id,
        top_n=req.top_n,
        weights=weights_dict,
        discovery_slider=req.discovery_slider
    )

    # 4. Formater le film de référence
    ref_brief = MovieBriefOut(
        id=ref_movie.id,
        title=ref_movie.title,
        year=ref_movie.year,
        poster_path=ref_movie.poster_path,
        backdrop_path=ref_movie.backdrop_path,
        vote_average=ref_movie.vote_average,
        vote_count=ref_movie.vote_count,
        pacing=ref_movie.pacing,
        genres=[g.name for g in ref_movie.genres],
        atmosphere_tags=[t.name for t in ref_movie.atmosphere_tags]
    )

    # 5. Formater la liste de recommandations
    items = [RecommendationItem(**item) for item in raw_results]

    return RecommendResponse(
        reference_movie=ref_brief,
        recommendations=items
    )
