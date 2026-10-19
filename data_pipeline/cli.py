"""
cli.py — Interface CLI interactive pour tester le moteur CineBook (Jalon 1.3)

Permet de :
  1. Choisir un film de référence parmi les 142 du dataset.
  2. Ajuster interactivement les curseurs de poids :
     - Focus Ambiance (Atmosphere)
     - Focus Esthétique Visuelle (Couleurs)
     - Focus Genres
     - Focus Rythme (Pacing)
     - Bonus Découverte (Favorise les films méconnus)
  3. Visualiser le top 5 des recommandations avec les scores détaillés
     et l'explication "Pourquoi ce film ?".

Usage :
  python -m data_pipeline.cli
"""

import io
import sys
from typing import Dict

# Fix encodage Windows
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from data_pipeline.recommender import CineRecommender


def render_bar(score: float, width: int = 15) -> str:
    """Affiche une barre de progression ASCII."""
    filled = int(score * width)
    return "█" * filled + "░" * (width - filled)


def interactive_cli():
    print(f"\n{'═'*66}")
    print("  🎬 CineBook — Moteur de Recommandation Interactif (CLI)")
    print(f"{'═'*66}\n")

    recommender = CineRecommender()
    print(f"  Base chargée : {len(recommender.movies)} films disponibles.\n")

    while True:
        print("─" * 66)
        try:
            query = input("🔍 Entrez le titre d'un film (ex: Blade Runner 2049, Amelie, Seven) [ou 'q' pour quitter] : ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nÀ bientôt sur CineBook ! 🍿\n")
            break
        if query.lower() in ("q", "quit", "exit"):
            print("\nÀ bientôt sur CineBook ! 🍿\n")
            break

        ref_movie = recommender.find_movie_by_title(query)
        if not ref_movie:
            print(f"❌ Film '{query}' introuvable dans le Golden 142. Essayez un autre titre.")
            continue

        print(f"\n✅ Film sélectionné : {ref_movie['title']} ({ref_movie['year']})")
        print(f"   • Genres     : {', '.join(ref_movie['genres'])}")
        print(f"   • Atmosphère : {', '.join(ref_movie['atmosphere_tags'][:5])}")
        print(f"   • Rythme     : {ref_movie['pacing']:.2f}/1.00")
        print(f"   • Note TMDb  : {ref_movie['vote_average']:.1f}/10 ({ref_movie['vote_count']} votes)\n")

        print("🎛️  Choisissez un profil de recommandation :")
        print("  1. Équilibré (Standard)")
        print("  2. Focus Ambiance & Émotion (Pondère fortement l'atmosphère)")
        print("  3. Focus Esthétique Visuelle (Pondère les teintes et la palette)")
        print("  4. Explorateur Indé (Fort bonus aux pépites méconnues)")
        print("  5. Personnalisé (Régler chaque curseur manuellement)")
        
        choice = input("\nVotre choix [1-5, défaut: 1] : ").strip() or "1"

        weights = {"genre": 1.0, "atmosphere": 1.5, "visual": 1.2, "era": 0.5, "pacing": 0.8}
        discovery = 0.3

        if choice == "2":
            weights = {"genre": 0.5, "atmosphere": 3.0, "visual": 1.0, "era": 0.3, "pacing": 1.0}
            discovery = 0.3
        elif choice == "3":
            weights = {"genre": 0.5, "atmosphere": 1.0, "visual": 3.5, "era": 0.2, "pacing": 0.5}
            discovery = 0.3
        elif choice == "4":
            weights = {"genre": 1.0, "atmosphere": 1.5, "visual": 1.2, "era": 0.5, "pacing": 0.8}
            discovery = 0.9  # Forte prime découverte
        elif choice == "5":
            print("\nEntrez une valeur entre 0.0 et 5.0 pour chaque curseur :")
            try:
                weights["atmosphere"] = float(input("  • Poids Atmosphère [défaut 1.5] : ") or "1.5")
                weights["visual"]     = float(input("  • Poids Visuel [défaut 1.2] : ") or "1.2")
                weights["genre"]      = float(input("  • Poids Genre [défaut 1.0] : ") or "1.0")
                weights["pacing"]     = float(input("  • Poids Rythme [défaut 0.8] : ") or "0.8")
                discovery             = float(input("  • Curseurs Découverte 0.0 - 1.0 [défaut 0.3] : ") or "0.3")
            except ValueError:
                print("Valeur invalide, conservation des réglages par défaut.")

        recs = recommender.recommend(
            reference_id=ref_movie["id"],
            top_n=5,
            weights=weights,
            discovery_slider=discovery
        )

        print(f"\n{'═'*66}")
        print(f"  🎯 Top 5 des recommandations pour '{ref_movie['title']}'")
        print(f"{'═'*66}\n")

        for idx, rec in enumerate(recs, 1):
            score_bar = render_bar(rec["score"])
            print(f"#{idx}  {rec['title']} ({rec['year']})")
            print(f"    Score CineBook : {score_bar}  {int(rec['score'] * 100)}% (Base: {int(rec['base_similarity']*100)}% | Découverte: x{rec['discovery_factor']})")
            print(f"    Genres         : {', '.join(rec['genres'][:3])} | Note: {rec['vote_average']:.1f}/10")
            print(f"    💡 Pourquoi ce film ? {rec['explanation']}")
            print()


if __name__ == "__main__":
    interactive_cli()
