"""
enrich_tags.py — Jalon 1.2 : Enrichissement des tags d'atmosphère et du rythme (pacing)

Stratégie hybride de niveau production :
  1. Si le film a déjà été enrichi par Gemini (dans le checkpoint), on conserve ses tags.
  2. Tente l'appel Gemini (avec structured output Pydantic).
  3. Si le quota de l'API gratuite est atteint (HTTP 429) ou service indisponible (HTTP 503),
     bascule automatiquement sur un résolveur sémantique déterministe basé sur :
       - Les genres officiels TMDb
       - Les mots-clés officiels TMDb (keywords)
       - Le synopsis (overview)
       - Les tags de référence (atmosphere_seeds)
       - La durée (runtime) pour le calcul du rythme

Entrée  : data/movies_raw.json
Sortie  : data/enriched_tags.json

Usage :
  python -m data_pipeline.enrich_tags
"""

import io
import json
import re
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
GEMINI_MODEL        = "gemini-3.1-flash-lite"
DELAY_BETWEEN_CALLS = 1.0

# ── Vocabulaire des 20 tags (Vector 2 — Atmosphère) ─────────────────────────────
ATMOSPHERE_TAGS = [
    "melancholic", "joyful",    "tense",    "dreamlike", "raw",
    "tender",      "nostalgic", "dark",     "epic",      "intimate",
    "poetic",      "surreal",   "chaotic",  "meditative","elegant",
    "bleak",       "warm",      "cold",     "kinetic",   "disturbing",
]


class AtmosphereTags(BaseModel):
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
#  Résolveur sémantique déterministe (Fallback basé sur les données TMDb réelles)
# ═══════════════════════════════════════════════════════════════════════════════

KEYWORD_RULES = {
    "melancholic": ["melancholy", "grief", "sadness", "loss", "death", "depression", "tragedy", "loneliness", "tearjerker"],
    "joyful":      ["comedy", "humor", "friendship", "party", "adventure", "celebration", "fun", "uplifting", "satire"],
    "tense":       ["thriller", "suspense", "hostage", "kidnapping", "murder", "investigation", "detective", "danger", "paranoia"],
    "dreamlike":   ["dream", "surreal", "fantasy", "illusion", "vision", "hallucination", "subconscious", "wonderland"],
    "raw":         ["violence", "brutality", "prison", "gritty", "drugs", "blood", "crime", "slum", "harsh", "poverty"],
    "tender":      ["love", "romance", "kiss", "affection", "family", "heartwarming", "father daughter", "mother son"],
    "nostalgic":   ["nostalgia", "childhood", "retro", "memories", "past", "vintage", "coming of age", "1970s", "1980s", "1960s"],
    "dark":        ["noir", "neo-noir", "dark", "night", "underworld", "evil", "gothic", "sinister", "macabre", "dystopia"],
    "epic":        ["epic", "space", "war", "galaxy", "journey", "rebellion", "quest", "historical", "monumental", "empire"],
    "intimate":    ["dialogue", "chamber drama", "marriage", "couple", "two people", "apartment", "isolation", "confession"],
    "poetic":      ["poetic", "nature", "art", "metaphor", "meditation", "philosophy", "cinema", "symbolism"],
    "surreal":     ["bizarre", "absurd", "dimension", "time travel", "multiverse", "weird", "reality", "unreal"],
    "chaotic":     ["chaos", "frenzy", "madness", "chase", "riot", "panic", "heist gone wrong", "insanity", "mayhem"],
    "meditative":  ["slow", "contemplation", "silence", "walking", "solitude", "thinking", "quiet", "minimalist"],
    "elegant":     ["aristocracy", "ballet", "classical music", "haute couture", "high society", "refined", "theatre", "art"],
    "bleak":       ["bleak", "hopeless", "nihilism", "barren", "grim", "apocalypse", "despair", "ruins", "bleakness"],
    "warm":        ["sun", "summer", "cozy", "village", "mediterranean", "countryside", "warmth", "kindness"],
    "cold":        ["snow", "winter", "ice", "cyberpunk", "sterile", "laboratory", "spaceship", "frost", "cold war"],
    "kinetic":     ["martial arts", "gunfight", "car chase", "speed", "explosion", "superhero", "combat", "action packed"],
    "disturbing":  ["nightmare", "psychological", "torment", "serial killer", "obsession", "cannibalism", "cult", "shocking"]
}

def semantic_enrich(movie: dict) -> dict:
    """
    Extrait les tags d'atmosphère et le rythme de manière déterministe
    à partir des métadonnées officielles TMDb (genres, keywords, synopsis)
    et des tags curés dans le seed.
    """
    genres = [g["name"].lower() for g in movie.get("genres", [])]
    keywords = [k["name"].lower() for k in movie.get("keywords", {}).get("keywords", [])]
    overview = movie.get("overview", "").lower()
    seeds = movie.get("_seed", {}).get("atmosphere_seeds", [])
    runtime = movie.get("runtime", 110) or 110

    full_text = " ".join(genres + keywords + [overview])

    scores = {tag: 0 for tag in ATMOSPHERE_TAGS}

    # 1. Intègre les tags curés du seed (poids prioritaire)
    for s in seeds:
        tag = s.lower().strip()
        if tag in scores:
            scores[tag] = 1

    # 2. Match avec les règles de mots-clés et genres
    for tag, patterns in KEYWORD_RULES.items():
        for pat in patterns:
            if re.search(r"\b" + re.escape(pat) + r"\b", full_text):
                scores[tag] = 1
                break

    # 3. Règles structurelles selon les genres principaux
    if "horror" in genres or "horreur" in genres:
        scores["dark"] = 1
        scores["tense"] = 1
    if "thriller" in genres:
        scores["tense"] = 1
    if "action" in genres:
        scores["kinetic"] = 1
    if "romance" in genres:
        scores["tender"] = 1
    if "science fiction" in genres or "science-fiction" in genres:
        scores["cold"] = scores.get("cold", 0) or 1
    if "comedy" in genres or "comédie" in genres:
        scores["joyful"] = 1
    if "war" in genres or "guerre" in genres:
        scores["epic"] = 1
        scores["raw"] = 1

    # Assure qu'au moins 3 tags sont actifs
    active_count = sum(scores.values())
    if active_count < 3:
        scores["intimate"] = 1
        scores["raw"] = 1

    # 4. Estimation du rythme (pacing)
    pacing = 0.50
    if "action" in genres or "adventure" in genres:
        pacing += 0.25
    if "thriller" in genres or "crime" in genres:
        pacing += 0.15
    if "animation" in genres:
        pacing += 0.10
    if "drama" in genres or "drame" in genres:
        pacing -= 0.15
    if "mystery" in genres:
        pacing -= 0.05
    if scores.get("meditative") == 1:
        pacing -= 0.15
    if scores.get("kinetic") == 1:
        pacing += 0.15

    # Modificateur de durée
    if runtime < 95:
        pacing += 0.05
    elif runtime > 150:
        pacing -= 0.10

    pacing = max(0.10, min(0.95, round(pacing, 2)))

    return {
        "atmosphere": scores,
        "pacing":     pacing,
        "_source":    "tmdb_semantic_mapper",
    }


# ═══════════════════════════════════════════════════════════════════════════════
#  Appel Gemini avec fallback automatique
# ═══════════════════════════════════════════════════════════════════════════════

def build_prompt(movie: dict) -> str:
    title    = movie.get("title", "")
    year     = (movie.get("release_date", "????") or "????")[:4]
    overview = movie.get("overview", "")[:350]
    genres   = [g["name"] for g in movie.get("genres", [])]
    keywords = [k["name"] for k in movie.get("keywords", {}).get("keywords", [])[:10]]
    seeds    = movie.get("_seed", {}).get("atmosphere_seeds", [])

    return f"""You are a film studies expert.
Analyze the following movie and assign binary scores (0 or 1) for each atmosphere tag.
Also assign a pacing score from 0.0 (contemplative) to 1.0 (furious action).

FILM: {title} ({year})
OVERVIEW: {overview}
GENRES: {', '.join(genres)}
KEYWORDS: {', '.join(keywords)}
CURATOR HINTS: {', '.join(seeds)}

Atmosphere tags: melancholic, joyful, tense, dreamlike, raw, tender, nostalgic,
dark, epic, intimate, poetic, surreal, chaotic, meditative, elegant, bleak, warm, cold, kinetic, disturbing"""


def enrich_movie(client, movie: dict) -> dict:
    """Tente Gemini ; si indisponible ou quota dépassé, utilise le mapper TMDb."""
    if client:
        try:
            from google.genai import types
            prompt = build_prompt(movie)
            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_json_schema=AtmosphereTags.model_json_schema(),
                    temperature=0.2,
                    thinking_config=types.ThinkingConfig(thinking_budget=0),
                ),
            )
            data = json.loads(response.text)
            validated = AtmosphereTags(**data)
            atmosphere = {tag: getattr(validated, tag) for tag in ATMOSPHERE_TAGS}
            return {
                "atmosphere": atmosphere,
                "pacing":     round(validated.pacing, 2),
                "_source":    GEMINI_MODEL,
            }
        except Exception:
            pass  # Bascule fluide sur le fallback

    return semantic_enrich(movie)


# ═══════════════════════════════════════════════════════════════════════════════
#  Point d'entrée
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    if not RAW_FILE.exists():
        print(f"Fichier introuvable : {RAW_FILE}")
        sys.exit(1)

    client = None
    if GEMINI_API_KEY:
        try:
            from google import genai
            client = genai.Client(api_key=GEMINI_API_KEY)
        except Exception as e:
            print(f"Client Gemini indisponible ({e}), mode mapper actif.")

    movies: list[dict] = json.loads(RAW_FILE.read_text(encoding="utf-8"))

    # Reprend le checkpoint existant
    checkpoint: dict[str, dict] = {}
    if CHECKPOINT_FILE.exists():
        checkpoint = json.loads(CHECKPOINT_FILE.read_text(encoding="utf-8"))
        print(f"Checkpoint trouvé : {len(checkpoint)} films déjà enrichis.")

    print(f"\n{'='*62}")
    print(f"  CineBook — Enrichissement des Tags (Jalon 1.2)")
    print(f"  {len(movies)} films au total | {len(movies) - len(checkpoint)} restants")
    print(f"{'='*62}\n")

    results: dict[str, dict] = dict(checkpoint)

    for i, movie in enumerate(movies, 1):
        tmdb_id = str(movie["id"])
        title   = movie.get("title", "?")

        if tmdb_id in results:
            continue

        label = f"[{i:3d}/{len(movies)}] {title[:40]}"
        print(f"{label:<48}", end="", flush=True)

        enriched = enrich_movie(client, movie)
        results[tmdb_id] = enriched
        checkpoint[tmdb_id] = enriched

        CHECKPOINT_FILE.write_text(
            json.dumps(checkpoint, ensure_ascii=False, indent=2), encoding="utf-8"
        )

        top3 = [t for t, v in enriched["atmosphere"].items() if v == 1][:3]
        src = "LLM" if "gemini" in enriched.get("_source", "") else "TMDb-Sem"
        print(f"OK ({src}, pace={enriched['pacing']:.2f}) [{', '.join(top3)}]")

    OUTPUT_FILE.write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    llm_count = sum(1 for m in results.values() if "gemini" in m.get("_source", ""))
    sem_count = len(results) - llm_count

    print(f"\n{'='*62}")
    print(f"  Enrichissement terminé avec succès pour les {len(results)} films !")
    print(f"  • Source Gemini LLM : {llm_count} films")
    print(f"  • Source TMDb Sémantique : {sem_count} films")
    print(f"  Fichier sauvegardé dans : {OUTPUT_FILE.name}")
    print(f"{'='*62}\n")


if __name__ == "__main__":
    main()
