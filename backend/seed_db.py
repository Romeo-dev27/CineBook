"""
seed_db.py — Jalon 2 : Peuplement de la base de données SQLite

Lit feature_matrix.json et color_features.json pour insérer
les 142 films avec leurs genres, tags, palettes et vecteurs
dans la base de données SQLite locale (cinebook.db).

Usage :
  python -m backend.seed_db
"""

import io
import json
import sys
from pathlib import Path

# Fix encodage Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from backend.database import engine, SessionLocal, Base
from backend.models import Movie, Genre, AtmosphereTag, MovieColorPalette, MovieVector

ROOT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT_DIR / "data_pipeline" / "data"
MATRIX_FILE = DATA_DIR / "feature_matrix.json"
COLOR_FILE  = DATA_DIR / "color_features.json"


def init_db():
    """Crée toutes les tables selon les modèles SQLAlchemy."""
    print("🔨 Création des tables dans SQLite...")
    Base.metadata.create_all(bind=engine)


def seed_database():
    if not MATRIX_FILE.exists():
        print(f"❌ Fichier introuvable : {MATRIX_FILE}")
        print("Exécute d'abord le pipeline du Jalon 1 : python -m data_pipeline.build_vectors")
        sys.exit(1)

    movies_data = json.loads(MATRIX_FILE.read_text(encoding="utf-8"))
    color_data = json.loads(COLOR_FILE.read_text(encoding="utf-8")) if COLOR_FILE.exists() else {}

    db = SessionLocal()

    try:
        print(f"\n{'═'*62}")
        print(f"  🎬 CineBook — Peuplement SQLite (Jalon 2)")
        print(f"  Films à insérer : {len(movies_data)}")
        print(f"{'═'*62}\n")

        # 1. Gestion des caches pour les entités uniques (Genres et Tags)
        genre_cache = {g.name: g for g in db.query(Genre).all()}
        tag_cache = {t.name: t for t in db.query(AtmosphereTag).all()}

        inserted_count = 0
        updated_count = 0

        for mid_str, data in movies_data.items():
            tmdb_id = data["id"]
            existing = db.query(Movie).filter(Movie.id == tmdb_id).first()

            # Résolution des genres
            movie_genres = []
            for gname in data.get("genres", []):
                if gname not in genre_cache:
                    new_g = Genre(name=gname)
                    db.add(new_g)
                    db.flush()
                    genre_cache[gname] = new_g
                movie_genres.append(genre_cache[gname])

            # Résolution des tags d'atmosphère
            movie_tags = []
            for tname in data.get("atmosphere_tags", []):
                if tname not in tag_cache:
                    new_t = AtmosphereTag(name=tname)
                    db.add(new_t)
                    db.flush()
                    tag_cache[tname] = new_t
                movie_tags.append(tag_cache[tname])

            # Palette de couleurs (10 features HSV)
            col_info = color_data.get(mid_str, {})
            palette_obj = MovieColorPalette(
                warmth=float(col_info.get("warmth", 0.0)),
                coolness=float(col_info.get("coolness", 0.0)),
                avg_brightness=float(col_info.get("avg_brightness", 0.0)),
                avg_saturation=float(col_info.get("avg_saturation", 0.0)),
                contrast=float(col_info.get("contrast", 0.0)),
                colorfulness=float(col_info.get("colorfulness", 0.0)),
                darkness_ratio=float(col_info.get("darkness_ratio", 0.0)),
                vividness_ratio=float(col_info.get("vividness_ratio", 0.0)),
                teal_ratio=float(col_info.get("teal_ratio", 0.0)),
                orange_ratio=float(col_info.get("orange_ratio", 0.0)),
            )

            # Vecteurs précalculés (JSON)
            vecs = data["vectors"]
            vector_obj = MovieVector(
                genre_vec=vecs["genre"],
                atmosphere_vec=vecs["atmosphere"],
                visual_vec=vecs["visual"],
                era_scalar=float(vecs["era"][0]),
                pacing_scalar=float(vecs["pacing"][0]),
            )

            if existing:
                # Mise à jour
                existing.title = data["title"]
                existing.original_title = data.get("original_title", "")
                existing.year = data["year"]
                existing.overview = data.get("overview", "")
                existing.poster_path = data.get("poster_path", "")
                existing.backdrop_path = data.get("backdrop_path", "")
                existing.vote_average = data.get("vote_average", 0.0)
                existing.vote_count = data.get("vote_count", 0)
                existing.popularity = data.get("popularity", 0.0)
                existing.pacing = data.get("pacing", 0.5)
                existing.genres = movie_genres
                existing.atmosphere_tags = movie_tags
                existing.color_palette = palette_obj
                existing.feature_vector = vector_obj
                updated_count += 1
            else:
                # Nouvelle insertion
                new_movie = Movie(
                    id=tmdb_id,
                    title=data["title"],
                    original_title=data.get("original_title", ""),
                    year=data["year"],
                    overview=data.get("overview", ""),
                    poster_path=data.get("poster_path", ""),
                    backdrop_path=data.get("backdrop_path", ""),
                    vote_average=data.get("vote_average", 0.0),
                    vote_count=data.get("vote_count", 0),
                    popularity=data.get("popularity", 0.0),
                    pacing=data.get("pacing", 0.5),
                    genres=movie_genres,
                    atmosphere_tags=movie_tags,
                    color_palette=palette_obj,
                    feature_vector=vector_obj,
                )
                db.add(new_movie)
                inserted_count += 1

        db.commit()

        total_movies = db.query(Movie).count()
        total_genres = db.query(Genre).count()
        total_tags = db.query(AtmosphereTag).count()

        print(f"✅ Succès du peuplement SQLite :")
        print(f"   • Films dans la base  : {total_movies} (nouveaux: {inserted_count}, maj: {updated_count})")
        print(f"   • Genres uniques      : {total_genres}")
        print(f"   • Tags d'atmosphère   : {total_tags}")
        print(f"{'═'*62}\n")

    except Exception as e:
        db.rollback()
        print(f"❌ Erreur lors du peuplement : {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    init_db()
    seed_database()
