"""
extract_colors.py — Jalon 1.2 : Extraction de la palette visuelle

Pour chaque film du dataset, ce script :
  1. Télécharge 2 images "backdrop" depuis TMDb (résolution w780)
  2. Analyse chaque image pixel par pixel en espace colorimétrique HSV
  3. Calcule 10 caractéristiques visuelles qui formeront le Vector 3
  4. Moyenne ces caractéristiques sur les 2 backdrops
  5. Sauvegarde dans data/color_features.json

Les 10 dimensions du Vector 3 (Palette Visuelle) :
  1. warmth          → proportion de pixels chauds (rouge/orange/jaune)
  2. coolness        → proportion de pixels froids (bleu/cyan/violet)
  3. avg_brightness  → luminosité moyenne (0=très sombre, 1=très clair)
  4. avg_saturation  → saturation moyenne (0=gris, 1=très coloré)
  5. contrast        → écart-type de la luminosité (faible=plat, fort=contrasté)
  6. colorfulness    → écart-type de la saturation (faible=uniforme, fort=varié)
  7. darkness_ratio  → proportion de pixels très sombres (V < 0.35)
  8. vividness_ratio → proportion de pixels très saturés (S > 0.65)
  9. teal_ratio      → proportion de teinte teal/cyan (style cyberpunk/thriller)
  10. orange_ratio   → proportion de teinte orange (style action/chaud)

Usage :
  python -m data_pipeline.extract_colors
"""

import io
import json
import sys
import time
from pathlib import Path
from typing import Optional

import numpy as np
import requests
from PIL import Image

# Fix encodage Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from data_pipeline.config import TMDB_API_KEY, TMDB_IMAGE_BASE_URL, DATA_DIR

# ── Fichiers ────────────────────────────────────────────────────────────────────
RAW_FILE        = DATA_DIR / "movies_raw.json"
OUTPUT_FILE     = DATA_DIR / "color_features.json"
CHECKPOINT_FILE = DATA_DIR / "_checkpoint_colors.json"
BACKDROPS_DIR   = DATA_DIR / "backdrops"
BACKDROPS_DIR.mkdir(parents=True, exist_ok=True)

# ── Paramètres ──────────────────────────────────────────────────────────────────
IMG_RESOLUTION     = "w780"    # Taille TMDb : assez grande pour les couleurs, pas trop lourde
MAX_BACKDROPS      = 2         # On prend les 2 premiers backdrops par film
THUMBNAIL_SIZE     = (200, 112) # On redimensionne pour accélérer l'analyse pixel
DOWNLOAD_DELAY     = 0.20      # Délai entre téléchargements (politesse réseau)
REQUEST_TIMEOUT    = 20


# ═══════════════════════════════════════════════════════════════════════════════
#  Téléchargement d'une image backdrop
# ═══════════════════════════════════════════════════════════════════════════════

def download_backdrop(file_path: str, dest: Path) -> bool:
    """
    Télécharge une image backdrop TMDb et la sauvegarde localement.

    Pourquoi sauvegarder localement ?
      → Si on relance le script, on n'a pas à re-télécharger les images déjà
        présentes (économie de bande passante et de temps).

    Args:
        file_path : le chemin TMDb ex. "/abc123.jpg"
        dest      : le fichier local de destination

    Returns:
        True si le téléchargement a réussi (ou si le fichier existait déjà).
    """
    if dest.exists():
        return True  # Déjà téléchargé lors d'une précédente exécution

    url = f"{TMDB_IMAGE_BASE_URL}/{IMG_RESOLUTION}{file_path}"
    try:
        resp = requests.get(url, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        dest.write_bytes(resp.content)
        return True
    except requests.RequestException:
        return False


# ═══════════════════════════════════════════════════════════════════════════════
#  Analyse colorimétrique d'une image
# ═══════════════════════════════════════════════════════════════════════════════

def _rgb_to_hsv(rgb: np.ndarray) -> np.ndarray:
    """
    Convertit un tableau NumPy de pixels RGB (valeurs 0-255) en HSV.

    On implémente la conversion manuellement (sans OpenCV) pour ne dépendre
    que de NumPy et Pillow.

    H ∈ [0, 1]  (0=rouge, 0.33=vert, 0.67=bleu, 1=rouge)
    S ∈ [0, 1]  (0=gris, 1=couleur pure)
    V ∈ [0, 1]  (0=noir, 1=blanc)
    """
    # Normalise en [0, 1]
    r, g, b = rgb[..., 0] / 255.0, rgb[..., 1] / 255.0, rgb[..., 2] / 255.0

    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    # Value
    v = cmax

    # Saturation
    s = np.where(cmax == 0, 0.0, delta / cmax)

    # Hue
    h = np.zeros_like(r)
    mask_r = (cmax == r) & (delta != 0)
    mask_g = (cmax == g) & (delta != 0)
    mask_b = (cmax == b) & (delta != 0)

    h[mask_r] = ((g[mask_r] - b[mask_r]) / delta[mask_r]) % 6
    h[mask_g] = (b[mask_g] - r[mask_g]) / delta[mask_g] + 2
    h[mask_b] = (r[mask_b] - g[mask_b]) / delta[mask_b] + 4
    h = h / 6.0  # Normalise en [0, 1]

    return np.stack([h, s, v], axis=-1)


def analyze_image(img_path: Path) -> Optional[dict]:
    """
    Analyse les couleurs d'une image et retourne un dictionnaire de 10 features.

    Stratégie :
      1. Redimensionne à une petite vignette (200×112 px = 22 400 pixels)
         → Rapide à analyser tout en étant représentatif
      2. Convertit en HSV
      3. Calcule les 10 métriques sur tous les pixels

    Returns:
        Dictionnaire avec les 10 features (float entre 0 et 1), ou None si erreur.
    """
    try:
        img = Image.open(img_path).convert("RGB")
        img = img.resize(THUMBNAIL_SIZE, Image.LANCZOS)  # LANCZOS = meilleure qualité de redimensionnement
        pixels = np.array(img)                            # Shape: (H, W, 3) en RGB
    except Exception:
        return None

    # ── Conversion HSV ────────────────────────────────────────────────────────
    hsv = _rgb_to_hsv(pixels)
    h = hsv[..., 0].flatten()  # Teinte    (0-1)
    s = hsv[..., 1].flatten()  # Saturation (0-1)
    v = hsv[..., 2].flatten()  # Valeur     (0-1)

    # ── Feature 1 & 2 : Warmth / Coolness ─────────────────────────────────────
    # Pixels chauds  : rouge (h<0.083 ou h>0.916), orange (0.05-0.11), jaune (0.11-0.19)
    # Pixels froids  : vert-bleu (0.33-0.75)
    # On ne compte que les pixels suffisamment saturés (S > 0.15) pour éviter
    # les gris qui n'ont pas vraiment de teinte significative
    saturated = s > 0.15
    warm_mask = saturated & ((h < 0.19) | (h > 0.92))
    cool_mask = saturated & (h > 0.40) & (h < 0.75)
    warmth    = float(warm_mask.mean())
    coolness  = float(cool_mask.mean())

    # ── Features 3-6 : Statistiques globales ──────────────────────────────────
    avg_brightness = float(v.mean())
    avg_saturation = float(s.mean())
    contrast       = float(v.std())          # Écart-type de la luminosité
    colorfulness   = float(s.std())          # Écart-type de la saturation

    # ── Feature 7 & 8 : Ratios extrêmes ───────────────────────────────────────
    darkness_ratio  = float((v < 0.35).mean())   # Pixels très sombres
    vividness_ratio = float((s > 0.65).mean())   # Pixels très saturés

    # ── Feature 9 & 10 : Teal et Orange (signature cinéma) ────────────────────
    # Le "Orange & Teal" est le color grading le plus utilisé au cinéma.
    # Teal  : cyan/bleu-vert H ∈ [0.46, 0.58]   (films de SF, thriller)
    # Orange: H ∈ [0.04, 0.11] avec S > 0.4     (films d'action, peau humaine chaude)
    teal_mask   = saturated & (h > 0.46) & (h < 0.58)
    orange_mask = (s > 0.40) & (h > 0.04) & (h < 0.12)
    teal_ratio   = float(teal_mask.mean())
    orange_ratio = float(orange_mask.mean())

    return {
        "warmth":          round(warmth,          4),
        "coolness":        round(coolness,         4),
        "avg_brightness":  round(avg_brightness,   4),
        "avg_saturation":  round(avg_saturation,   4),
        "contrast":        round(contrast,         4),
        "colorfulness":    round(colorfulness,     4),
        "darkness_ratio":  round(darkness_ratio,   4),
        "vividness_ratio": round(vividness_ratio,  4),
        "teal_ratio":      round(teal_ratio,       4),
        "orange_ratio":    round(orange_ratio,     4),
    }


# ═══════════════════════════════════════════════════════════════════════════════
#  Traitement d'un film
# ═══════════════════════════════════════════════════════════════════════════════

def process_movie_colors(movie: dict) -> Optional[dict]:
    """
    Télécharge les backdrops d'un film et calcule la palette moyenne.

    Retourne un dict de 10 features moyennées sur MAX_BACKDROPS images,
    ou None si aucun backdrop n'était disponible.
    """
    tmdb_id   = movie["id"]
    backdrops = movie.get("images", {}).get("backdrops", [])

    if not backdrops:
        return None

    # Trie par vote_count décroissant → prend les backdrops les mieux notés
    backdrops_sorted = sorted(backdrops, key=lambda b: b.get("vote_count", 0), reverse=True)
    selected = backdrops_sorted[:MAX_BACKDROPS]

    movie_dir = BACKDROPS_DIR / str(tmdb_id)
    movie_dir.mkdir(exist_ok=True)

    all_features = []
    for i, backdrop in enumerate(selected):
        file_path = backdrop["file_path"]
        dest      = movie_dir / f"backdrop_{i}{Path(file_path).suffix}"

        success = download_backdrop(file_path, dest)
        time.sleep(DOWNLOAD_DELAY)

        if not success:
            continue

        features = analyze_image(dest)
        if features:
            all_features.append(features)

    if not all_features:
        return None

    # Moyenne des features sur toutes les images téléchargées
    keys = all_features[0].keys()
    averaged = {k: round(sum(f[k] for f in all_features) / len(all_features), 4) for k in keys}
    averaged["_n_images"] = len(all_features)  # On note combien d'images ont contribué
    return averaged


# ═══════════════════════════════════════════════════════════════════════════════
#  Point d'entrée
# ═══════════════════════════════════════════════════════════════════════════════

def main() -> None:
    if not RAW_FILE.exists():
        print(f"Fichier introuvable : {RAW_FILE}")
        print("Lance d'abord : python -m data_pipeline.fetch_movies")
        sys.exit(1)

    movies: list[dict] = json.loads(RAW_FILE.read_text(encoding="utf-8"))

    # Checkpoint
    checkpoint: dict[str, dict] = {}
    if CHECKPOINT_FILE.exists():
        checkpoint = json.loads(CHECKPOINT_FILE.read_text(encoding="utf-8"))
        print(f"Checkpoint trouve : {len(checkpoint)} films deja traites.")

    remaining = [m for m in movies if str(m["id"]) not in checkpoint]

    print(f"\n{'='*62}")
    print(f"  CineBook - Extraction de couleurs (Jalon 1.2)")
    print(f"  {len(movies)} films | {len(remaining)} a traiter")
    print(f"  ~{len(remaining) * MAX_BACKDROPS * DOWNLOAD_DELAY:.0f}s estimees")
    print(f"{'='*62}\n")

    results: dict[str, dict] = dict(checkpoint)
    no_backdrop = []

    for i, movie in enumerate(remaining, 1):
        tmdb_id = movie["id"]
        title   = movie.get("title", "?")
        label   = f"[{i:3d}/{len(remaining)}] {title[:45]}"
        print(f"{label:<52}", end="", flush=True)

        features = process_movie_colors(movie)

        if features:
            results[str(tmdb_id)] = features
            checkpoint[str(tmdb_id)] = features
            CHECKPOINT_FILE.write_text(
                json.dumps(checkpoint, ensure_ascii=False, indent=2), encoding="utf-8"
            )
            n = features["_n_images"]
            bright = features["avg_brightness"]
            warm   = features["warmth"]
            print(f"OK ({n} img, bright={bright:.2f}, warm={warm:.2f})")
        else:
            no_backdrop.append(title)
            print("-- pas de backdrop")

    # Sauvegarde finale
    OUTPUT_FILE.write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"\n{'='*62}")
    print(f"  {len(results)} films avec palette dans {OUTPUT_FILE.name}")
    if no_backdrop:
        print(f"  {len(no_backdrop)} sans backdrop : {', '.join(no_backdrop[:5])}")
    print(f"{'='*62}\n")


if __name__ == "__main__":
    main()
