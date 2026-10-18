"""
test_tmdb.py — Script de validation de la connexion à l'API TMDb.

Ce script est le premier test concret du projet CineBook.
Il vérifie 3 choses :
  1. Que ta clé API TMDb est valide
  2. Que la recherche par titre fonctionne
  3. Que l'on peut récupérer les détails complets d'un film

Utilisation :
    python data_pipeline/test_tmdb.py

Prérequis :
    pip install -r data_pipeline/requirements.txt
    Avoir un fichier .env avec TMDB_API_KEY=...
"""

import sys
import json
import requests

# Import de notre config centralisée (gère le chargement du .env)
from data_pipeline.config import TMDB_API_KEY, TMDB_BASE_URL


# ── Constantes de test ──────────────────────────────────────────────────────────
TEST_MOVIE_TITLE = "Blade Runner 2049"  # Film de référence pour nos tests
TEST_MOVIE_TMDB_ID = 335984             # ID TMDb connu de Blade Runner 2049


def test_api_key_is_set() -> None:
    """Vérifie que la clé API n'est pas vide."""
    assert TMDB_API_KEY, "TMDB_API_KEY est vide dans .env"
    print(f"  ✅ Clé API détectée : {TMDB_API_KEY[:6]}{'*' * (len(TMDB_API_KEY) - 6)}")


def test_search_movie() -> dict:
    """
    Appelle l'endpoint /search/movie et vérifie que Blade Runner 2049
    apparaît dans les résultats.
    
    Returns:
        Le premier résultat de la recherche (dict).
    """
    url = f"{TMDB_BASE_URL}/search/movie"
    params = {
        "api_key": TMDB_API_KEY,
        "query": TEST_MOVIE_TITLE,
        "language": "fr-FR",
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()

    data = response.json()
    results = data.get("results", [])

    assert len(results) > 0, f"Aucun résultat pour '{TEST_MOVIE_TITLE}'"

    # On prend le premier résultat (le plus pertinent)
    first = results[0]
    print(f"  ✅ Recherche OK — Premier résultat : '{first['title']}' (id={first['id']})")
    return first


def test_get_movie_details() -> dict:
    """
    Appelle l'endpoint /movie/{id} pour récupérer tous les détails
    d'un film, y compris les genres — ce dont on aura besoin au Jalon 1.
    
    Returns:
        Le dictionnaire complet des détails du film.
    """
    url = f"{TMDB_BASE_URL}/movie/{TEST_MOVIE_TMDB_ID}"
    params = {
        "api_key": TMDB_API_KEY,
        "language": "fr-FR",
        # append_to_response nous permet de tout récupérer en 1 seul appel API
        "append_to_response": "keywords,credits,images",
    }

    response = requests.get(url, params=params, timeout=10)
    response.raise_for_status()

    movie = response.json()

    # Vérifions les champs essentiels pour notre pipeline
    required_fields = ["id", "title", "genres", "vote_average", "release_date", "overview"]
    for field in required_fields:
        assert field in movie, f"Champ '{field}' manquant dans la réponse TMDb"

    genres = [g["name"] for g in movie.get("genres", [])]
    print(f"  ✅ Détails OK — Titre : '{movie['title']}'")
    print(f"     • Année     : {movie['release_date'][:4]}")
    print(f"     • Note      : {movie['vote_average']:.1f}/10")
    print(f"     • Genres    : {', '.join(genres)}")
    print(f"     • Synopsis  : {movie['overview'][:80]}…")

    return movie


def main() -> None:
    """Point d'entrée principal — exécute les 3 tests en séquence."""
    print("\n" + "═" * 60)
    print("  🎬 CineBook — Test de connexion TMDb (Jalon 0)")
    print("═" * 60)

    tests = [
        ("1. Clé API présente dans .env", test_api_key_is_set),
        ("2. Endpoint /search/movie",     test_search_movie),
        ("3. Endpoint /movie/{id}",       test_get_movie_details),
    ]

    failed = False
    for name, test_fn in tests:
        print(f"\n🔍 {name}")
        try:
            test_fn()
        except (AssertionError, requests.RequestException, KeyError) as exc:
            print(f"  ❌ ÉCHEC : {exc}")
            failed = True

    print("\n" + "═" * 60)
    if failed:
        print("  ⚠️  Certains tests ont échoué. Relis les erreurs ci-dessus.")
        sys.exit(1)
    else:
        print("  🎉 Tous les tests passent ! Prêt pour le Jalon 1.")
    print("═" * 60 + "\n")


if __name__ == "__main__":
    main()
