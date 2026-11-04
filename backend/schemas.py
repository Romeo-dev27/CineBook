"""
schemas.py — Schémas Pydantic pour la validation et la sérialisation des API REST FastAPI

Définit les formats d'entrée et de sortie pour les films, les filtres,
les palettes de couleurs et le moteur de recommandation.
"""

from typing import List, Dict, Optional
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict, field_validator, model_validator




# ── Genres et Tags ─────────────────────────────────────────────────────────────

class GenreOut(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)


class AtmosphereTagOut(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)


# ── Palette Colorimétrique ─────────────────────────────────────────────────────

class ColorPaletteOut(BaseModel):
    warmth: float
    coolness: float
    avg_brightness: float
    avg_saturation: float
    contrast: float
    colorfulness: float
    darkness_ratio: float
    vividness_ratio: float
    teal_ratio: float
    orange_ratio: float

    model_config = ConfigDict(from_attributes=True)


# ── Plateformes de Streaming (Watch Providers) ─────────────────────────────────

class WatchProviderOut(BaseModel):
    id: int = Field(description="ID TMDb de la plateforme de streaming")
    name: str = Field(description="Nom de la plateforme (ex: Netflix, Amazon Prime Video, Disney+)")
    logo_path: Optional[str] = Field(default=None, description="Chemin d'icône/logo TMDb")

    model_config = ConfigDict(from_attributes=True)


# ── Films ──────────────────────────────────────────────────────────────────────

class MovieBriefOut(BaseModel):
    id: int
    title: str
    year: int
    poster_path: Optional[str] = None
    backdrop_path: Optional[str] = None
    vote_average: float
    vote_count: int
    pacing: float
    genres: List[str] = Field(default_factory=list)
    atmosphere_tags: List[str] = Field(default_factory=list)
    streaming_providers: List[WatchProviderOut] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class MovieDetailOut(MovieBriefOut):
    original_title: Optional[str] = None
    overview: Optional[str] = None
    popularity: float
    color_palette: Optional[ColorPaletteOut] = None

    model_config = ConfigDict(from_attributes=True)


# ── Requête & Réponse de Recommandation ────────────────────────────────────────

class RecommendationWeights(BaseModel):
    atmosphere: float = Field(default=1.5, ge=0.0, le=5.0, description="Poids de l'ambiance et des émotions")
    visual: float = Field(default=1.2, ge=0.0, le=5.0, description="Poids de l'esthétique et de la palette")
    genre: float = Field(default=1.0, ge=0.0, le=5.0, description="Poids des genres cinématographiques")
    era: float = Field(default=0.5, ge=0.0, le=5.0, description="Poids de la proximité temporelle")
    pacing: float = Field(default=0.8, ge=0.0, le=5.0, description="Poids de la cadence/rythme")


class RecommendRequest(BaseModel):
    movie_id: Optional[int] = Field(default=None, description="ID TMDb d'un film de référence unique (legacy)")
    movie_ids: Optional[List[int]] = Field(default=None, description="Liste d'IDs TMDb des films de référence (multi-seeds)")
    top_n: int = Field(default=5, ge=1, le=20, description="Nombre de recommandations souhaitées")
    weights: Optional[RecommendationWeights] = Field(default_factory=RecommendationWeights)
    discovery_slider: float = Field(default=0.3, ge=0.0, le=1.0, description="0.0: blockbusters tolérés, 1.0: boost maximal aux pépites méconnues")
    provider: Optional[str] = Field(default=None, description="Filtre optionnel par plateforme de streaming (ex: Netflix, Amazon Prime Video, Apple TV)")

    def get_movie_ids(self) -> List[int]:
        if self.movie_ids and len(self.movie_ids) > 0:
            return list(dict.fromkeys(self.movie_ids))
        if self.movie_id is not None:
            return [self.movie_id]
        return []

    @model_validator(mode="after")
    def validate_reference_seeds(self):
        ids = self.get_movie_ids()
        if not ids:
            raise ValueError("Au moins un film de référence doit être spécifié (movie_id ou movie_ids).")
        return self


class RecommendationItem(BaseModel):
    id: int
    title: str
    year: int
    poster_path: Optional[str] = None
    backdrop_path: Optional[str] = None
    vote_average: float
    vote_count: int
    genres: List[str]
    atmosphere_tags: List[str]
    pacing: float
    score: float
    base_similarity: float
    discovery_factor: float
    sub_scores: Dict[str, float]
    explanation: str
    streaming_providers: List[WatchProviderOut] = Field(default_factory=list)


class RecommendResponse(BaseModel):
    reference_movie: MovieBriefOut
    reference_movies: List[MovieBriefOut] = Field(default_factory=list)
    recommendations: List[RecommendationItem]


# ── Jalon 5 : Authentification & Watchlist ────────────────────────────────────

class UserRegister(BaseModel):
    email: str = Field(description="Adresse email de l'utilisateur")
    password: str = Field(min_length=6, description="Mot de passe (minimum 6 caractères)")

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        clean = v.strip().lower()
        if "@" not in clean or "." not in clean.split("@")[-1]:
            raise ValueError("Format d'adresse email invalide.")
        return clean


class UserLogin(BaseModel):
    email: str = Field(description="Adresse email")
    password: str = Field(description="Mot de passe")


class UserOut(BaseModel):
    id: int
    email: str
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class WatchlistAddRequest(BaseModel):
    movie_id: int = Field(description="ID TMDb du film à ajouter")
    status: str = Field(default="to_watch", description="Statut : 'to_watch', 'watched', ou 'favorite'")
    notes: Optional[str] = Field(default=None, description="Notes personnelles facultatives")


class WatchlistUpdateRequest(BaseModel):
    status: Optional[str] = Field(default=None, description="Nouveau statut : 'to_watch', 'watched', 'favorite'")
    notes: Optional[str] = Field(default=None, description="Notes personnelles")


class WatchlistItemOut(BaseModel):
    id: int
    movie_id: int
    status: str
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    movie: MovieBriefOut

    model_config = ConfigDict(from_attributes=True)

