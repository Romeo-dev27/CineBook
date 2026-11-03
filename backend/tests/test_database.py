"""
test_database.py — Tests d'intégrité de la base de données SQLite (Jalon 2)

Vérifie :
  1. La présence et l'intégrité des 142 films dans SQLite.
  2. La validité des relations Many-to-Many (Genres et AtmosphereTags).
  3. La validité des relations One-to-One (MovieColorPalette et MovieVector).
  4. L'application des contraintes d'intégrité et de cascade (suppression propre).
  5. Les requêtes de filtrage par genre et par tag d'atmosphère.
"""

import pytest
try:
    from database import SessionLocal, engine
    from models import Movie, Genre, AtmosphereTag, MovieColorPalette, MovieVector
except ImportError:
    from backend.database import SessionLocal, engine
    from backend.models import Movie, Genre, AtmosphereTag, MovieColorPalette, MovieVector


@pytest.fixture(scope="module")
def db_session():
    """Fournit une session de base de données pour les tests."""
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def test_database_counts(db_session):
    """Vérifie le compte exact des films et des entités normalisées."""
    movie_count = db_session.query(Movie).count()
    assert movie_count == 142, f"Attendu: 142 films, Trouvé: {movie_count}"

    genre_count = db_session.query(Genre).count()
    assert genre_count >= 15, f"Trop peu de genres: {genre_count}"

    tag_count = db_session.query(AtmosphereTag).count()
    assert tag_count == 20, f"Attendu: 20 tags d'atmosphère, Trouvé: {tag_count}"


def test_blade_runner_2049_integrity(db_session):
    """Vérifie l'intégrité complète d'un film phare avec toutes ses relations."""
    movie = db_session.query(Movie).filter(Movie.id == 335984).first()
    assert movie is not None, "Blade Runner 2049 introuvable dans SQLite."

    # Métadonnées
    assert movie.title == "Blade Runner 2049"
    assert movie.year == 2017
    assert movie.vote_count > 10000

    # Relations Many-to-Many
    genre_names = [g.name for g in movie.genres]
    assert "Science Fiction" in genre_names

    tag_names = [t.name for t in movie.atmosphere_tags]
    assert len(tag_names) >= 3

    # Relation One-to-One Palette
    palette = movie.color_palette
    assert palette is not None
    assert 0.0 <= palette.warmth <= 1.0
    assert 0.0 <= palette.avg_brightness <= 1.0
    assert 0.0 <= palette.teal_ratio <= 1.0

    # Relation One-to-One Vecteurs
    vector = movie.feature_vector
    assert vector is not None
    assert len(vector.genre_vec) == 19
    assert len(vector.atmosphere_vec) == 20
    assert len(vector.visual_vec) == 10
    assert 0.0 <= vector.era_scalar <= 1.0


def test_filter_by_genre(db_session):
    """Vérifie que la jointure sur Genre fonctionne correctement."""
    sf_movies = (
        db_session.query(Movie)
        .join(Movie.genres)
        .filter(Genre.name == "Science Fiction")
        .all()
    )
    assert len(sf_movies) >= 10
    titles = [m.title for m in sf_movies]
    assert "Blade Runner 2049" in titles
    assert "The Matrix" in titles or "Interstellar" in titles


def test_filter_by_atmosphere_tag(db_session):
    """Vérifie que la jointure sur AtmosphereTag fonctionne."""
    melancholic_movies = (
        db_session.query(Movie)
        .join(Movie.atmosphere_tags)
        .filter(AtmosphereTag.name == "melancholic")
        .all()
    )
    assert len(melancholic_movies) >= 20
    titles = [m.title for m in melancholic_movies]
    assert any("Godfather" in t or "Blade Runner" in t or "Her" in t for t in titles)


def test_cascade_delete_temporary_movie(db_session):
    """Vérifie que la suppression d'un film supprime en cascade sa palette et ses vecteurs."""
    # Création d'un film temporaire
    temp_movie = Movie(
        id=9999999,
        title="Test Cascade Movie",
        year=2025,
        pacing=0.5
    )
    temp_palette = MovieColorPalette(
        movie_id=9999999,
        warmth=0.5,
        coolness=0.5
    )
    temp_vector = MovieVector(
        movie_id=9999999,
        genre_vec=[0.0] * 19,
        atmosphere_vec=[0.0] * 20,
        visual_vec=[0.0] * 10,
        era_scalar=0.9,
        pacing_scalar=0.5
    )
    temp_movie.color_palette = temp_palette
    temp_movie.feature_vector = temp_vector

    db_session.add(temp_movie)
    db_session.commit()

    # Vérifie qu'ils existent
    assert db_session.query(MovieColorPalette).filter_by(movie_id=9999999).first() is not None
    assert db_session.query(MovieVector).filter_by(movie_id=9999999).first() is not None

    # Suppression du film
    db_session.delete(temp_movie)
    db_session.commit()

    # Vérifie que la suppression en cascade a nettoyé les tables enfants
    assert db_session.query(MovieColorPalette).filter_by(movie_id=9999999).first() is None
    assert db_session.query(MovieVector).filter_by(movie_id=9999999).first() is None
