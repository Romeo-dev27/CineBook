"""
models.py — Modèles relationnels SQLAlchemy 2.0 pour CineBook

Schéma :
  - Movie (films avec métadonnées TMDb)
  - Genre (genres normalisés en relation Many-to-Many)
  - AtmosphereTag (les 20 tags d'ambiance en relation Many-to-Many)
  - MovieColorPalette (les 10 caractéristiques de palette visuelle en One-to-One)
  - MovieVector (les 5 sous-vecteurs précalculés normalisés en One-to-One)
"""

from typing import List
from sqlalchemy import (
    Column, Integer, String, Float, Text, ForeignKey, Table, JSON
)
from sqlalchemy.orm import relationship
from backend.database import Base

# ── Tables d'association Many-to-Many ──────────────────────────────────────────

movie_genres = Table(
    "movie_genres",
    Base.metadata,
    Column("movie_id", Integer, ForeignKey("movies.id", ondelete="CASCADE"), primary_key=True),
    Column("genre_id", Integer, ForeignKey("genres.id", ondelete="CASCADE"), primary_key=True),
)

movie_atmosphere_tags = Table(
    "movie_atmosphere_tags",
    Base.metadata,
    Column("movie_id", Integer, ForeignKey("movies.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("atmosphere_tags.id", ondelete="CASCADE"), primary_key=True),
)


# ── Modèles principaux ─────────────────────────────────────────────────────────

class Genre(Base):
    __tablename__ = "genres"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)

    movies = relationship("Movie", secondary=movie_genres, back_populates="genres")

    def __repr__(self) -> str:
        return f"<Genre(id={self.id}, name='{self.name}')>"


class AtmosphereTag(Base):
    __tablename__ = "atmosphere_tags"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)

    movies = relationship("Movie", secondary=movie_atmosphere_tags, back_populates="atmosphere_tags")

    def __repr__(self) -> str:
        return f"<AtmosphereTag(id={self.id}, name='{self.name}')>"


class Movie(Base):
    __tablename__ = "movies"

    id = Column(Integer, primary_key=True, index=True)  # ID TMDb
    title = Column(String(255), nullable=False, index=True)
    original_title = Column(String(255), nullable=True)
    year = Column(Integer, nullable=False, index=True)
    overview = Column(Text, nullable=True)
    poster_path = Column(String(255), nullable=True)
    backdrop_path = Column(String(255), nullable=True)
    vote_average = Column(Float, default=0.0)
    vote_count = Column(Integer, default=0)
    popularity = Column(Float, default=0.0)
    pacing = Column(Float, default=0.5)  # 0.0 (lent) à 1.0 (rapide)

    # Relations
    genres = relationship("Genre", secondary=movie_genres, back_populates="movies", lazy="joined")
    atmosphere_tags = relationship("AtmosphereTag", secondary=movie_atmosphere_tags, back_populates="movies", lazy="joined")
    
    color_palette = relationship(
        "MovieColorPalette",
        back_populates="movie",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="joined"
    )
    feature_vector = relationship(
        "MovieVector",
        back_populates="movie",
        uselist=False,
        cascade="all, delete-orphan",
        lazy="joined"
    )

    def __repr__(self) -> str:
        return f"<Movie(id={self.id}, title='{self.title}', year={self.year})>"


class MovieColorPalette(Base):
    __tablename__ = "movie_color_palettes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    movie_id = Column(Integer, ForeignKey("movies.id", ondelete="CASCADE"), unique=True, nullable=False)

    warmth = Column(Float, default=0.0)
    coolness = Column(Float, default=0.0)
    avg_brightness = Column(Float, default=0.0)
    avg_saturation = Column(Float, default=0.0)
    contrast = Column(Float, default=0.0)
    colorfulness = Column(Float, default=0.0)
    darkness_ratio = Column(Float, default=0.0)
    vividness_ratio = Column(Float, default=0.0)
    teal_ratio = Column(Float, default=0.0)
    orange_ratio = Column(Float, default=0.0)

    movie = relationship("Movie", back_populates="color_palette")

    def __repr__(self) -> str:
        return f"<MovieColorPalette(movie_id={self.movie_id}, warmth={self.warmth:.2f}, coolness={self.coolness:.2f})>"


class MovieVector(Base):
    __tablename__ = "movie_vectors"

    id = Column(Integer, primary_key=True, autoincrement=True)
    movie_id = Column(Integer, ForeignKey("movies.id", ondelete="CASCADE"), unique=True, nullable=False)

    genre_vec = Column(JSON, nullable=False)        # 19D
    atmosphere_vec = Column(JSON, nullable=False)   # 20D
    visual_vec = Column(JSON, nullable=False)       # 10D
    era_scalar = Column(Float, nullable=False)      # 1D
    pacing_scalar = Column(Float, nullable=False)   # 1D

    movie = relationship("Movie", back_populates="feature_vector")

    def __repr__(self) -> str:
        return f"<MovieVector(movie_id={self.movie_id})>"
