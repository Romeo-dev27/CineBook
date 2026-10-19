"""
schemas.py — Schémas Pydantic pour la validation et la sérialisation des API REST FastAPI

Définit les formats d'entrée et de sortie pour les films, les filtres,
les palettes de couleurs et le moteur de recommandation.
"""

from typing import List, Dict, Optional
from pydantic import BaseModel, Field, ConfigDict


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
    movie_id: int = Field(description="ID TMDb du film de référence")
    top_n: int = Field(default=5, ge=1, le=20, description="Nombre de recommandations souhaitées")
    weights: Optional[RecommendationWeights] = Field(default_factory=RecommendationWeights)
    discovery_slider: float = Field(default=0.3, ge=0.0, le=1.0, description="0.0: blockbusters tolérés, 1.0: boost maximal aux pépites méconnues")


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


class RecommendResponse(BaseModel):
    reference_movie: MovieBriefOut
    recommendations: List[RecommendationItem]
