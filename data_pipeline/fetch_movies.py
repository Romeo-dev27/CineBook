"""
fetch_movies.py — Jalon 1.1 : Récupération des données brutes TMDb

Charge les 150 films de movies_seed.json, appelle l'API TMDb pour récupérer
les détails complets de chacun, valide les résultats par comparaison de titre,
et sauvegarde tout dans data/movies_raw.json.

Fonctionnalités :
  - Checkpoint : reprend où il s'est arrêté en cas d'interruption
  - Validation : compare le titre TMDb avec le titre attendu
  - Fallback   : recherche par titre+année si l'ID est incorrect
  - Rate limit : respecte la limite de l'API TMDb (~40 req / 10 s)

Usage :
  python -m data_pipeline.fetch_movies
"""

import io
import json
import re
import sys
import time
from pathlib import Path
from typing import Optional

import requests

# Force UTF-8 sur Windows (le terminal utilise cp1252 par défaut,
# ce qui ne supporte pas les caractères Unicode comme ═ ou ✅).
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from data_pipeline.config import TMDB_API_KEY, TMDB_BASE_URL, DATA_DIR

# ── Fichiers ────────────────────────────────────────────────────────────────────
SEED_FILE       = Path(__file__).parent / "movies_seed.json"
OUTPUT_FILE     = DATA_DIR / "movies_raw.json"
CHECKPOINT_FILE = DATA_DIR / "_checkpoint_fetch.json"

# ── Paramètres ──────────────────────────────────────────────────────────────────
DELAY_BETWEEN_REQUESTS = 0.28   # 0.28s → environ 35 req/10s (sous la limite de 40)
REQUEST_TIMEOUT        = 15     # secondes avant de considérer la requête comme échouée


# ═══════════════════════════════════════════════════════════════════════════════
#  Utilitaires de comparaison de titres
# ═══════════════════════════════════════════════════════════════════════════════

def _normalize(text: str) -> str:
    """
    Nettoie un titre pour la comparaison insensible à la casse et ponctuation.

    Exemple :
      "Spider-Man: Into the Spider-Verse" → "spider man into the spider verse"
    """
    return re.sub(r"[^a-z0-9 ]", "", text.lower()).strip()


def _titles_similar(expected: str, actual: str, threshold: float = 0.6) -> bool:
    """
    Retourne True si les deux titres partagent au moins `threshold` fraction
    de leurs mots (ratio d'intersection sur les mots du titre attendu).

    On évite intentionnellement les dépendances comme python-Levenshtein
    pour garder l'installation simple.

    Exemples :
      ("Amelie", "Amélie") → True  (après normalisation unicode → ascii approx.)
      ("Blade Runner", "Blade Runner 2049") → False  (si threshold=0.6, 2/2=1 → True!)
      ("Her", "Her") → True
    """
    e_words = set(_normalize(expected).split())
    a_words = set(_normalize(actual).split())
    if not e_words:
        return False
    overlap = len(e_words & a_words) / len(e_words)
    return overlap >= threshold


# ═══════════════════════════════════════════════════════════════════════════════
#  Couche HTTP — appels à l'API TMDb
# ═══════════════════════════════════════════════════════════════════════════════

def _http_get(url: str, params: dict) -> dict:
    """Wrapper HTTP GET simple avec timeout. Lève HTTPError sur 4xx/5xx."""
    response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    response.raise_for_status()
    return response.json()


def fetch_by_id(tmdb_id: int) -> Optional[dict]:
    """
    Récupère les détails COMPLETS d'un film via son ID TMDb en 1 seul appel.

    On utilise append_to_response pour tout rassembler :
      - keywords : mots-clés TMDb (ex: "cyberpunk", "artificial intelligence")
      - credits  : casting + équipe (on extraira le réalisateur)
      - images   : liste des backdrops (pour l'extraction de couleurs au Jalon 1.2)

    include_image_language : on préfère les images sans texte (null) ou en anglais
    pour que l'extraction de couleurs ne soit pas polluée par des sous-titres.

    Retourne None si le film n'existe pas (404).
    """
    url = f"{TMDB_BASE_URL}/movie/{tmdb_id}"
    params = {
        "api_key":                TMDB_API_KEY,
        "language":               "en-US",
        "append_to_response":     "keywords,credits,images",
        "include_image_language": "en,null",
    }
    try:
        return _http_get(url, params)
    except requests.HTTPError as exc:
        if exc.response.status_code == 404:
            return None
        raise  # On re-lève les autres erreurs (500, rate limit 429, etc.)


def search_by_title(title: str, year: int) -> Optional[dict]:
    """
    Recherche un film par titre + année (stratégie de fallback).

    Appelé quand l'ID dans movies_seed.json est incorrect.
    Retourne les détails complets du résultat le plus populaire, ou None.
    """
    url = f"{TMDB_BASE_URL}/search/movie"
    params = {
        "api_key":       TMDB_API_KEY,
        "query":         title,
        "year":          year,
        "language":      "en-US",
        "include_adult": False,
    }
    data = _http_get(url, params)
    results = data.get("results", [])

    if not results:
        return None

    # TMDb trie déjà par pertinence, on prend le premier résultat
    best = results[0]
    time.sleep(DELAY_BETWEEN_REQUESTS)
    return fetch_by_id(best["id"])


# ═══════════════════════════════════════════════════════════════════════════════
#  Logique principale : traitement d'un film de la seed list
# ═══════════════════════════════════════════════════════════════════════════════

def process_seed(seed: dict) -> tuple[Optional[dict], str]:
    """
    Tente de récupérer et valider les données d'un film en 2 étapes :

    Étape 1 — Fetch par ID :
      → Si le titre TMDb correspond au titre attendu : ✅ succès immédiat.
      → Si non : on passe à l'étape 2 (l'ID était probablement incorrect).

    Étape 2 — Fallback par recherche titre+année :
      → On cherche le bon film et on le récupère par son vrai ID.

    Retourne (movie_data, status) avec status ∈ {"id_match", "title_search", "not_found"}
    """
    tmdb_id        = seed["tmdb_id"]
    expected_title = seed["title"]
    year           = seed["year"]

    # ── Étape 1 : par ID ─────────────────────────────────────────────────────
    data = fetch_by_id(tmdb_id)
    time.sleep(DELAY_BETWEEN_REQUESTS)

    if data:
        actual_title = data.get("title", "") or data.get("original_title", "")
        if _titles_similar(expected_title, actual_title):
            return data, "id_match"
        # L'ID pointe vers un autre film → on log et on essaie par titre
        print(
            f"\n    ⚠️  ID {tmdb_id} → '{actual_title}' ≠ '{expected_title}'"
            f" — recherche par titre..."
        )

    # ── Étape 2 : fallback par titre ─────────────────────────────────────────
    data = search_by_title(expected_title, year)
    time.sleep(DELAY_BETWEEN_REQUESTS)

    if data:
        return data, "title_search"

    return None, "not_found"


# ═══════════════════════════════════════════════════════════════════════════════
#  Point d'entrée
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    # ── Charger la seed list ─────────────────────────────────────────────────
    if not SEED_FILE.exists():
        print(f"❌ Fichier introuvable : {SEED_FILE}")
        sys.exit(1)

    seeds: list[dict] = json.loads(SEED_FILE.read_text(encoding="utf-8"))

    print(f"\n{'═' * 62}")
    print(f"  🎬 CineBook — Fetch Golden {len(seeds)} (Jalon 1.1)")
    print(f"{'═' * 62}")

    # ── Charger le checkpoint (reprend si le script a été interrompu) ─────────
    # Pourquoi un checkpoint ?
    #   150 films × ~0.56s = environ 84 secondes. Si la connexion coupe
    #   au film n°120, on ne veut pas recommencer depuis le début.
    checkpoint: dict[str, dict] = {}
    if CHECKPOINT_FILE.exists():
        checkpoint = json.loads(CHECKPOINT_FILE.read_text(encoding="utf-8"))
        print(f"\n♻️  Checkpoint trouvé — {len(checkpoint)} films déjà récupérés.")

    already_done = set(checkpoint.keys())
    remaining    = [s for s in seeds if str(s["tmdb_id"]) not in already_done]

    print(f"📋 {len(seeds)} films au total | {len(remaining)} à récupérer\n")

    # ── Boucle de fetch ───────────────────────────────────────────────────────
    results: list[dict] = list(checkpoint.values())
    failed:  list[dict] = []

    for i, seed in enumerate(remaining, start=1):
        label = f"[{i:3d}/{len(remaining)}] {seed['title']} ({seed['year']})"
        # Padding à 55 caractères pour que les ✅/❌ s'alignent
        print(f"{label:<55}", end="", flush=True)

        try:
            movie_data, status = process_seed(seed)
        except requests.RequestException as exc:
            print(f"❌ Erreur réseau : {exc}")
            failed.append(seed)
            continue

        if movie_data is None:
            print("❌ Introuvable sur TMDb")
            failed.append(seed)
            continue

        # Enrichissement : on injecte nos métadonnées de seed dans le dict TMDb
        # Elles seront utilisées aux étapes suivantes du pipeline
        movie_data["_seed"]         = seed
        movie_data["_fetch_status"] = status

        results.append(movie_data)
        checkpoint[str(seed["tmdb_id"])] = movie_data

        # ⚠️ On sauvegarde le checkpoint APRÈS CHAQUE FILM
        # C'est plus lent que de tout écrire à la fin, mais résistant aux pannes.
        CHECKPOINT_FILE.write_text(
            json.dumps(checkpoint, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        icon = "✅" if status == "id_match" else "🔄"
        print(f"{icon} id={movie_data['id']}")

    # ── Sauvegarde finale ─────────────────────────────────────────────────────
    OUTPUT_FILE.write_text(
        json.dumps(results, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"\n{'═' * 62}")
    print(f"  ✅ {len(results)} films sauvegardés dans :")
    print(f"     {OUTPUT_FILE}")

    if failed:
        print(f"\n  ❌ {len(failed)} film(s) introuvable(s) :")
        for s in failed:
            print(f"     • {s['title']} ({s['year']}) — ID seed={s['tmdb_id']}")
        print(
            "\n  → Pour chaque film ❌, vérifie son ID sur https://www.themoviedb.org"
            "\n    et corrige-le dans movies_seed.json, puis relance le script."
        )

    # ── Statistiques finales ──────────────────────────────────────────────────
    id_matches    = sum(1 for m in results if m.get("_fetch_status") == "id_match")
    title_matches = sum(1 for m in results if m.get("_fetch_status") == "title_search")
    print(f"\n  📊 Statistiques :")
    print(f"     • ID direct    : {id_matches} films")
    print(f"     • Recherche    : {title_matches} films (ID corrigé automatiquement)")
    print(f"{'═' * 62}\n")


if __name__ == "__main__":
    main()
