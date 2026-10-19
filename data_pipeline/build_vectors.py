"""
build_vectors.py — Jalon 1.3 : Construction des vecteurs normalisés de caractéristiques

Ce script fusionne les 3 sources de données :
  1. data/movies_raw.json     (genres TMDb, popularité, vote_count, année)
  2. data/color_features.json (palette visuelle 10D HSV)
  3. data/enriched_tags.json  (tags atmosphère 20D, rythme pacing)

Et génère :
  data/feature_matrix.json :
    Dictionnaire où chaque film contient ses 5 sous-vecteurs normalisés
    et ses métadonnées pour le moteur de recommandation.

Structure par film :
  {
    "id": 335984,
    "title": "Blade Runner 2049",
    "year": 2017,
    "vote_count": 13420,
    "popularity": 85.4,
    "poster_path": "/...",
    "vectors": {
      "genre": [0.0, 1.0, ...],       (19 dimensions, L2-normalisé)
      "atmosphere": [0.0, 1.0, ...],  (20 dimensions, L2-normalisé)
      "visual": [0.24, 0.55, ...],    (10 dimensions, L2-normalisé)
      "era": [0.93],                  (1 dimension, [0, 1])
      "pacing": [0.25]                (1 dimension, [0, 1])
    }
  }

Usage :
  python -m data_pipeline.build_vectors
"""

import io
import json
import sys
from pathlib import Path
import numpy as np

# Fix encodage Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from data_pipeline.config import DATA_DIR
from data_pipeline.enrich_tags import ATMOSPHERE_TAGS

# ── Fichiers ────────────────────────────────────────────────────────────────────
RAW_FILE      = DATA_DIR / "movies_raw.json"
COLOR_FILE    = DATA_DIR / "color_features.json"
ENRICH_FILE   = DATA_DIR / "enriched_tags.json"
OUTPUT_FILE   = DATA_DIR / "feature_matrix.json"

# ── Taxonomie des 19 genres standards TMDb ─────────────────────────────────────
TMDB_GENRES = [
    "Action", "Adventure", "Animation", "Comedy", "Crime",
    "Documentary", "Drama", "Family", "Fantasy", "History",
    "Horror", "Music", "Mystery", "Romance", "Science Fiction",
    "TV Movie", "Thriller", "War", "Western"
]

# ── Clés des 10 features couleur (Vector 3) ────────────────────────────────────
COLOR_KEYS = [
    "warmth", "coolness", "avg_brightness", "avg_saturation",
    "contrast", "colorfulness", "darkness_ratio", "vividness_ratio",
    "teal_ratio", "orange_ratio"
]

def l2_normalize(vec: np.ndarray) -> list[float]:
    """Normalise un vecteur en norme L2 euclidienne (longueur = 1.0)."""
    norm = np.linalg.norm(vec)
    if norm == 0:
        return vec.tolist()
    return (vec / norm).tolist()

def build_features() -> dict:
    raw_movies = json.loads(RAW_FILE.read_text(encoding="utf-8"))
    color_data = json.loads(COLOR_FILE.read_text(encoding="utf-8"))
    enrich_data = json.loads(ENRICH_FILE.read_text(encoding="utf-8"))

    matrix = {}

    for movie in raw_movies:
        mid = str(movie["id"])
        if mid not in enrich_data:
            continue

        colors = color_data.get(mid, {})
        tags_info = enrich_data[mid]
        atmo = tags_info.get("atmosphere", {})

        # 1. Vecteur Genres (19D)
        movie_genres = {g["name"] for g in movie.get("genres", [])}
        genre_vec = np.array([1.0 if g in movie_genres else 0.0 for g in TMDB_GENRES])
        genre_norm = l2_normalize(genre_vec)

        # 2. Vecteur Atmosphère (20D)
        atmo_vec = np.array([float(atmo.get(tag, 0)) for tag in ATMOSPHERE_TAGS])
        atmo_norm = l2_normalize(atmo_vec)

        # 3. Vecteur Visuel (10D)
        vis_vec = np.array([float(colors.get(k, 0.5)) for k in COLOR_KEYS])
        vis_norm = l2_normalize(vis_vec)

        # 4. Vecteur Époque (1D) : normalisé entre 1920 et 2026
        rel_date = movie.get("release_date", "2000") or "2000"
        try:
            year = int(rel_date[:4])
        except ValueError:
            year = 2000
        era_scalar = max(0.0, min(1.0, (year - 1920) / (2026 - 1920)))

        # 5. Vecteur Rythme / Pacing (1D)
        pacing_scalar = float(tags_info.get("pacing", 0.5))

        matrix[mid] = {
            "id": movie["id"],
            "title": movie.get("title", ""),
            "original_title": movie.get("original_title", ""),
            "year": year,
            "overview": movie.get("overview", ""),
            "poster_path": movie.get("poster_path", ""),
            "backdrop_path": movie.get("backdrop_path", ""),
            "vote_average": movie.get("vote_average", 0.0),
            "vote_count": movie.get("vote_count", 0),
            "popularity": movie.get("popularity", 0.0),
            "genres": [g["name"] for g in movie.get("genres", [])],
            "atmosphere_tags": [t for t, val in atmo.items() if val == 1],
            "pacing": pacing_scalar,
            "vectors": {
                "genre": genre_norm,
                "atmosphere": atmo_norm,
                "visual": vis_norm,
                "era": [round(era_scalar, 4)],
                "pacing": [round(pacing_scalar, 4)]
            }
        }

    return matrix

def main() -> None:
    print(f"\n{'='*62}")
    print(f"  CineBook — Construction de la Matrice Vectorielle (Jalon 1.3)")
    print(f"{'='*62}\n")

    matrix = build_features()
    OUTPUT_FILE.write_text(json.dumps(matrix, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"  Matrice construite avec succès : {len(matrix)} films.")
    print(f"  Fichier de sortie : {OUTPUT_FILE.name}")
    print(f"{'='*62}\n")

if __name__ == "__main__":
    main()
