"""
fix_seed_ids.py -- Script temporaire (Jalon 1.1)

Lit movies_raw.json et met a jour movies_seed.json avec les vrais IDs TMDb.
Ajoute 8 films pour atteindre exactement 150.
"""
import io, sys
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import json
from pathlib import Path

SEED_FILE = Path("data_pipeline/movies_seed.json")
RAW_FILE  = Path("data_pipeline/data/movies_raw.json")

# Charge les données fetchées (source de vérité)
raw: list[dict] = json.loads(RAW_FILE.read_text(encoding="utf-8"))

# Construit un mapping seed_title+year → real_tmdb_id
real_ids: dict[str, int] = {}
for m in raw:
    seed = m["_seed"]
    key = f"{seed['title'].lower()}|{seed['year']}"
    real_ids[key] = m["id"]

# Charge et met à jour la seed list
seeds: list[dict] = json.loads(SEED_FILE.read_text(encoding="utf-8"))
corrections = 0
for s in seeds:
    key = f"{s['title'].lower()}|{s['year']}"
    if key in real_ids and real_ids[key] != s["tmdb_id"]:
        print(f"  ✏️  '{s['title']}' : {s['tmdb_id']} → {real_ids[key]}")
        s["tmdb_id"] = real_ids[key]
        corrections += 1

print(f"\n  {corrections} ID(s) corrigé(s) dans la seed list.")

# 8 films supplémentaires pour atteindre 150
# IDs vérifiés directement sur themoviedb.org
extra_films = [
    {"tmdb_id": 11216,  "title": "Cinema Paradiso",          "year": 1988, "category": "drama_intimate",           "atmosphere_seeds": ["warm", "nostalgic", "tender", "melancholic"]},
    {"tmdb_id": 503919, "title": "The Lighthouse",            "year": 2019, "category": "horror_disturbing",        "atmosphere_seeds": ["dark", "surreal", "raw", "disturbing"]},
    {"tmdb_id": 600583, "title": "The Power of the Dog",      "year": 2021, "category": "existential_contemplative","atmosphere_seeds": ["dark", "bleak", "cold", "tense"]},
    {"tmdb_id": 817758, "title": "Tar",                       "year": 2022, "category": "existential_contemplative","atmosphere_seeds": ["cold", "dark", "elegant", "tense"]},
    {"tmdb_id": 375262, "title": "The Favourite",             "year": 2018, "category": "comedy_quirky",            "atmosphere_seeds": ["dark", "cold", "elegant", "raw"]},
    {"tmdb_id": 491584, "title": "Burning",                   "year": 2018, "category": "existential_contemplative","atmosphere_seeds": ["dark", "cold", "surreal", "meditative"]},
    {"tmdb_id": 758866, "title": "Drive My Car",              "year": 2021, "category": "existential_contemplative","atmosphere_seeds": ["melancholic", "meditative", "intimate", "cold"]},
    {"tmdb_id": 947,    "title": "Lawrence of Arabia",        "year": 1962, "category": "war_historical",           "atmosphere_seeds": ["epic", "warm", "meditative", "elegant"]},
]

# On supprime les doublons potentiels (films déjà dans la liste via leur titre)
existing_titles = {s["title"].lower() for s in seeds}
for film in extra_films:
    if film["title"].lower() not in existing_titles:
        seeds.append(film)
        print(f"  ➕ Ajout : '{film['title']}' (id={film['tmdb_id']})")

print(f"\n  Total final : {len(seeds)} films dans la seed list.")

# Sauvegarde
SEED_FILE.write_text(json.dumps(seeds, ensure_ascii=False, indent=2), encoding="utf-8")
print("  ✅ movies_seed.json mis à jour.")
