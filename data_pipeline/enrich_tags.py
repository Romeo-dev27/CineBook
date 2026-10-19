"""
enrich_tags.py — Jalon 1.2 : Enrichissement LLM des tags d'atmosphère

Pour chaque film, ce script appelle l'API Gemini pour enrichir les métadonnées
en assignant des scores précis sur notre vocabulaire de 20 tags atmosphériques,
plus un score de rythme (pacing).

Entrée  : data/movies_raw.json
Sortie  : data/enriched_tags.json

Structure de sortie par film :
  {
    "atmosphere": {
      "melancholic": 1, "dark": 1, "cold": 1, ...,  ← 0 ou 1 par tag
    },
    "pacing": 0.35,    ← de 0.0 (très lent) à 1.0 (très rapide)
    "_model": "gemini-3.8-flash"
  }

Vocabulaire des 20 tags (Vector 2 — Atmosphère) :
  melancholic, joyful, tense, dreamlike, raw, tender, nostalgic,
  dark, epic, intimate, poetic, surreal, chaotic, meditative,
  elegant, bleak, warm, cold, kinetic, disturbing

Usage :
  python -m data_pipeline.enrich_tags
"""

import io
import json
import sys
import time
from pathlib import Path
from typing import Optional

from pydantic import BaseModel

# Fix encodage Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from data_pipeline.config import GEMINI_API_KEY, DATA_DIR

# ── Fichiers ────────────────────────────────────────────────────────────────────
RAW_FILE        = DATA_DIR / "movies_raw.json"
OUTPUT_FILE     = DATA_DIR / "enriched_tags.json"
CHECKPOINT_FILE = DATA_DIR / "_checkpoint_enrich.json"

# ── Paramètres Gemini ───────────────────────────────────────────────────────────
GEMINI_MODEL        = "gemini-3.8-flash"   # Rapide et économique pour du tagging
DELAY_BETWEEN_CALLS = 1.5                  # Secondes entre les appels (évite le rate limiting)
MAX_KEYWORDS        = 12                   # Nombre max de keywords TMDb à envoyer au LLM

# ── Vocabulaire des 20 tags (doit rester synchronisé avec recommender.py) ───────
ATMOSPHERE_TAGS = [
    "melancholic", "joyful",    "tense",    "dreamlike", "raw",
    "tender",      "nostalgic", "dark",     "epic",      "intimate",
    "poetic",      "surreal",   "chaotic",  "meditative","elegant",
    "bleak",       "warm",      "cold",     "kinetic",   "disturbing",
]


# ═══════════════════════════════════════════════════════════════════════════════
#  Schéma de sortie structurée (Pydantic → JSON Schema pour Gemini)
# ═══════════════════════════════════════════════════════════════════════════════

class AtmosphereTags(BaseModel):
    """
    Représente l'analyse d'atmosphère d'un film.

    On utilise Pydantic pour deux raisons :
      1. Gemini peut utiliser le JSON Schema de ce modèle pour garantir
         que sa réponse est bien formatée (structured output).
      2. On peut valider la réponse du LLM avant de la sauvegarder.
    """
    melancholic: int
    joyful:      int
    tense:       int
    dreamlike:   int
    raw:         int
    tender:      int
    nostalgic:   int
    dark:        int
    epic:        int
    intimate:    int
    poetic:      int
    surreal:     int
    chaotic:     int
    meditative:  int
    elegant:     int
    bleak:       int
    warm:        int
    cold:        int
    kinetic:     int
    disturbing:  int
    pacing:      float  # 0.0 (très lent) → 1.0 (très rapide)


# ═══════════════════════════════════════════════════════════════════════════════
#  Construction du prompt
# ═══════════════════════════════════════════════════════════════════════════════

def build_prompt(movie: dict) -> str:
    """
    Construit le prompt envoyé à Gemini pour analyser un film.

    On fournit :
      - Le titre et l'année (contexte principal)
      - Le synopsis (source primaire de l'atmosphère)
      - Les genres TMDb (signal fort)
      - Les keywords TMDb (détails fins : "neo-noir", "dystopia", etc.)
      - Les tags seeds de notre curation (signal secondaire)

    On ne fournit PAS d'exemple de sortie JSON dans le prompt car Gemini
    utilise le response_json_schema pour cela (avertissement dans la doc).
    """
    title    = movie.get("title", "")
    year     = (movie.get("release_date", "????") or "????")[:4]
    overview = movie.get("overview", "No overview available.")[:400]
    genres   = [g["name"] for g in movie.get("genres", [])]
    keywords = [k["name"] for k in movie.get("keywords", {}).get("keywords", [])[:MAX_KEYWORDS]]
    seeds    = movie.get("_seed", {}).get("atmosphere_seeds", [])

    return f"""You are a film studies expert specializing in cinematic atmosphere and mood analysis.

Analyze the following movie and assign binary scores (0 or 1) for each atmosphere tag.
Also assign a pacing score from 0.0 (very slow, contemplative) to 1.0 (very fast, action-packed).

FILM: {title} ({year})
OVERVIEW: {overview}
GENRES: {', '.join(genres) if genres else 'N/A'}
KEYWORDS: {', '.join(keywords) if keywords else 'N/A'}
INITIAL HINTS (curator notes): {', '.join(seeds) if seeds else 'N/A'}

IMPORTANT RULES:
- Score 1 if the tag strongly characterizes this film's viewing experience
- Score 0 if the tag is absent or very minor
- A film can have multiple tags (typically 3-7 active tags)
- Base your analysis on the film's overall tone, not just plot synopsis
- pacing: 0.0=meditative/slow-burn, 0.3=drama pace, 0.5=balanced, 0.7=thriller pace, 1.0=action non-stop

Atmosphere tags to score: melancholic, joyful, tense, dreamlike, raw, tender, nostalgic,
dark, epic, intimate, poetic, surreal, chaotic, meditative, elegant, bleak, warm, cold, kinetic, disturbing"""


# ═══════════════════════════════════════════════════════════════════════════════
#  Appel à l'API Gemini
# ═══════════════════════════════════════════════════════════════════════════════

def enrich_movie(client, movie: dict) -> Optional[dict]:
    """
    Appelle Gemini avec structured output pour obtenir les tags d'un film.

    On utilise response_json_schema (le schéma Pydantic converti en JSON Schema)
    pour garantir que Gemini répond dans le format exact attendu.
    Sans ça, le LLM pourrait inventer des noms de tags ou omettre des champs.

    Returns:
        Dictionnaire avec "atmosphere" (dict tag→0/1) et "pacing" (float),
        ou None si l'appel échoue.
    """
    from google import genai
    from google.genai import types

    prompt = build_prompt(movie)

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_json_schema=AtmosphereTags.model_json_schema(),
                temperature=0.2,       # Faible température → réponses cohérentes et reproductibles
                max_output_tokens=300, # Un JSON de 21 champs n'a pas besoin de plus
            ),
        )

        # Désérialise et valide avec Pydantic
        raw_json   = json.loads(response.text)
        validated  = AtmosphereTags(**raw_json)

        # Sépare les tags atmosphere du pacing
        atmosphere = {tag: getattr(validated, tag) for tag in ATMOSPHERE_TAGS}
        return {
            "atmosphere": atmosphere,
            "pacing":     round(validated.pacing, 3),
            "_model":     GEMINI_MODEL,
        }

    except Exception as exc:
        print(f"\n    ERREUR Gemini : {exc}")
        return None


# ═══════════════════════════════════════════════════════════════════════════════
#  Point d'entrée
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    # ── Vérifications préalables ─────────────────────────────────────────────
    if not RAW_FILE.exists():
        print(f"Fichier introuvable : {RAW_FILE}")
        sys.exit(1)

    if not GEMINI_API_KEY:
        print("GEMINI_API_KEY manquante dans .env")
        print("Obtiens ta cle sur https://aistudio.google.com/app/apikey")
        sys.exit(1)

    # ── Initialisation du client Gemini ──────────────────────────────────────
    from google import genai
    client = genai.Client(api_key=GEMINI_API_KEY)

    # ── Chargement des films ─────────────────────────────────────────────────
    movies: list[dict] = json.loads(RAW_FILE.read_text(encoding="utf-8"))

    # Checkpoint
    checkpoint: dict[str, dict] = {}
    if CHECKPOINT_FILE.exists():
        checkpoint = json.loads(CHECKPOINT_FILE.read_text(encoding="utf-8"))
        print(f"Checkpoint trouve : {len(checkpoint)} films deja enrichis.")

    remaining = [m for m in movies if str(m["id"]) not in checkpoint]

    estimated_s  = len(remaining) * DELAY_BETWEEN_CALLS
    estimated_min = estimated_s / 60

    print(f"\n{'='*62}")
    print(f"  CineBook - Enrichissement LLM (Jalon 1.2)")
    print(f"  Modele    : {GEMINI_MODEL}")
    print(f"  Films     : {len(movies)} total | {len(remaining)} a traiter")
    print(f"  Duree est.: ~{estimated_min:.1f} minutes")
    print(f"{'='*62}\n")

    results: dict[str, dict] = dict(checkpoint)
    failed: list[str] = []

    for i, movie in enumerate(remaining, 1):
        tmdb_id = str(movie["id"])
        title   = movie.get("title", "?")
        label   = f"[{i:3d}/{len(remaining)}] {title[:45]}"
        print(f"{label:<52}", end="", flush=True)

        enriched = enrich_movie(client, movie)
        time.sleep(DELAY_BETWEEN_CALLS)

        if enriched:
            results[tmdb_id]    = enriched
            checkpoint[tmdb_id] = enriched
            CHECKPOINT_FILE.write_text(
                json.dumps(checkpoint, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            # Affiche les 3 tags les plus saillants pour feedback immédiat
            top3 = [t for t, v in enriched["atmosphere"].items() if v == 1][:3]
            print(f"OK  pacing={enriched['pacing']:.2f}  [{', '.join(top3)}]")
        else:
            failed.append(title)
            print("ECHEC")

    # ── Sauvegarde finale ─────────────────────────────────────────────────────
    OUTPUT_FILE.write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"\n{'='*62}")
    print(f"  {len(results)} films enrichis dans {OUTPUT_FILE.name}")
    if failed:
        print(f"  {len(failed)} echecs : {', '.join(failed[:5])}")
    print(f"{'='*62}\n")


if __name__ == "__main__":
    main()
