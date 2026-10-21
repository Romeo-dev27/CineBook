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
    description="Prend un ou plusieurs films de référence (multi-seeds), des pondérations (Ambiance, Visuel, Genre, Époque, Rythme) et un curseur de découverte pour retourner les meilleures recommandations expliquées."
)
def recommend_movies(
    req: RecommendRequest,
    db: Session = Depends(get_db)
):
    # 1. Résoudre la liste des films de référence (supporte movie_ids ou movie_id unique)
    target_ids = req.get_movie_ids()
    if not target_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Au moins un film de référence doit être fourni."
        )

    # 2. Vérifier l'existence des films de référence
    ref_movies = db.query(Movie).filter(Movie.id.in_(target_ids)).all()
    if not ref_movies:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Film(s) de référence {target_ids} introuvable(s)."
        )

    # Conserver l'ordre original des IDs demandés
    id_to_movie = {m.id: m for m in ref_movies}
    ordered_ref_movies = [id_to_movie[mid] for mid in target_ids if mid in id_to_movie]

    # 3. Convertir les poids Pydantic en dictionnaire pour le service
    weights_dict = req.weights.model_dump() if req.weights else None

    # 4. Calculer les recommandations via le service basé sur la moyenne mathématique
    raw_results = recommender_service.recommend(
        db=db,
        reference_ids=target_ids,
        top_n=req.top_n,
        weights=weights_dict,
        discovery_slider=req.discovery_slider
    )

    # 5. Formater les films de référence
    ref_briefs = [
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
            atmosphere_tags=[t.name for t in m.atmosphere_tags]
        )
        for m in ordered_ref_movies
    ]

    # 6. Formater la liste de recommandations
    items = [RecommendationItem(**item) for item in raw_results]

    return RecommendResponse(
        reference_movie=ref_briefs[0],
        reference_movies=ref_briefs,
        recommendations=items
    )
