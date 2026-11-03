"""
watchlist.py — Routes REST pour la gestion des favoris et listes de films à voir (Watchlist)
"""

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from models import User, Movie, WatchlistItem
from schemas import (
    WatchlistAddRequest,
    WatchlistUpdateRequest,
    WatchlistItemOut,
    MovieBriefOut,
    WatchProviderOut,
)
from auth import get_current_user
from watch_providers_service import watch_providers_service

router = APIRouter(prefix="/api/watchlist", tags=["Watchlist & Favoris"])


def _to_watchlist_item_out(item: WatchlistItem) -> WatchlistItemOut:
    m = item.movie
    movie_brief = MovieBriefOut(
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
    return WatchlistItemOut(
        id=item.id,
        movie_id=item.movie_id,
        status=item.status,
        notes=item.notes,
        created_at=item.created_at,
        movie=movie_brief
    )


@router.get(
    "",
    response_model=List[WatchlistItemOut],
    summary="Récupérer la Watchlist de l'utilisateur connecté",
    description="Renvoie tous les films sauvegardés par l'utilisateur avec leurs métadonnées complètes."
)
def get_user_watchlist(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    items = (
        db.query(WatchlistItem)
        .filter(WatchlistItem.user_id == current_user.id)
        .order_by(WatchlistItem.created_at.desc())
        .all()
    )
    return [_to_watchlist_item_out(item) for item in items]


@router.post(
    "",
    response_model=WatchlistItemOut,
    status_code=status.HTTP_201_CREATED,
    summary="Ajouter un film à la Watchlist",
    description="Ajoute un film aux favoris ou à la liste 'à voir' de l'utilisateur."
)
def add_to_watchlist(
    req: WatchlistAddRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Vérifier que le film existe dans CineBook
    movie = db.query(Movie).filter(Movie.id == req.movie_id).first()
    if not movie:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Film avec l'ID {req.movie_id} introuvable."
        )

    # 2. Vérifier s'il est déjà dans la watchlist (comportement d'upsert)
    existing = (
        db.query(WatchlistItem)
        .filter(WatchlistItem.user_id == current_user.id, WatchlistItem.movie_id == req.movie_id)
        .first()
    )
    if existing:
        existing.status = req.status
        if req.notes is not None:
            existing.notes = req.notes
        db.commit()
        db.refresh(existing)
        return _to_watchlist_item_out(existing)

    # 3. Créer un nouvel élément
    item = WatchlistItem(
        user_id=current_user.id,
        movie_id=req.movie_id,
        status=req.status,
        notes=req.notes
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return _to_watchlist_item_out(item)


@router.delete(
    "/{movie_id}",
    summary="Retirer un film de la Watchlist",
    description="Supprime le film spécifié de la watchlist de l'utilisateur connecté."
)
def remove_from_watchlist(
    movie_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = (
        db.query(WatchlistItem)
        .filter(WatchlistItem.user_id == current_user.id, WatchlistItem.movie_id == movie_id)
        .first()
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ce film n'est pas dans votre watchlist."
        )

    db.delete(item)
    db.commit()
    return {"status": "success", "message": "Film retiré de votre watchlist."}


@router.patch(
    "/{movie_id}",
    response_model=WatchlistItemOut,
    summary="Mettre à jour le statut ou les notes d'un film dans la Watchlist"
)
def update_watchlist_item(
    movie_id: int,
    req: WatchlistUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = (
        db.query(WatchlistItem)
        .filter(WatchlistItem.user_id == current_user.id, WatchlistItem.movie_id == movie_id)
        .first()
    )
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ce film n'est pas dans votre watchlist."
        )

    if req.status is not None:
        item.status = req.status
    if req.notes is not None:
        item.notes = req.notes

    db.commit()
    db.refresh(item)
    return _to_watchlist_item_out(item)
