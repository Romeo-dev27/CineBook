"""
recommender.py — Moteur mathématique pur de recommandation CineBook

Ce module calcule la Similarité Cosinus Pondérée (Weighted Cosine Similarity)
sur les 5 sous-vecteurs de caractéristiques et applique un modificateur
de découverte pour favoriser les pépites méconnues.

Aucun framework de Machine Learning lourd n'est utilisé : uniquement du calcul
matriciel vectoriel pur avec NumPy.
"""

import json
import math
from pathlib import Path
from typing import List, Dict, Any, Optional
import numpy as np

from data_pipeline.config import DATA_DIR

import unicodedata

def _strip_accents(text: str) -> str:
    """Retire les accents pour une recherche insensible aux diacritiques (ex: Amelie -> Amélie)."""
    return "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    ).lower().strip()


class CineRecommender:
    """Moteur de recommandation basé sur la Similarité Cosinus Pondérée."""

    def __init__(self, matrix_path: Optional[Path] = None):
        path = matrix_path or (DATA_DIR / "feature_matrix.json")
        if not path.exists():
            raise FileNotFoundError(f"Matrice introuvable : {path}. Exécute d'abord build_vectors.py.")
        
        self.movies: Dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
        self._title_lookup = {
            _strip_accents(m["title"]): mid for mid, m in self.movies.items()
        }

    def find_movie_by_title(self, query: str) -> Optional[Dict[str, Any]]:
        """Recherche insensible à la casse et aux accents."""
        q = _strip_accents(query)
        # 1. Correspondance exacte
        if q in self._title_lookup:
            return self.movies[self._title_lookup[q]]
        # 2. Correspondance partielle
        for title, mid in self._title_lookup.items():
            if q in title:
                return self.movies[mid]
        return None

    @staticmethod
    def _cosine_sim(v1: List[float], v2: List[float]) -> float:
        """Produit scalaire de deux vecteurs L2-normalisés (équivalent cosinus)."""
        a = np.array(v1)
        b = np.array(v2)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return float(np.dot(a, b) / (norm_a * norm_b))

    @staticmethod
    def _scalar_sim(s1: float, s2: float) -> float:
        """Similarité de distance pour valeurs scalaires dans [0, 1]."""
        return max(0.0, 1.0 - abs(s1 - s2))

    def compute_discovery_factor(self, vote_count: int, discovery_weight: float) -> float:
        """
        Calcule le modificateur de découverte.
        - discovery_weight = 0.0 : aucun impact (tous les films sont traités à égalité).
        - discovery_weight > 0.0 : favorise les films à vote_count modéré et pénalise
          les blockbusters omniprésents (ex: Inception, The Dark Knight).
        """
        if discovery_weight <= 0.0:
            return 1.0
        
        # Log-dampening
        safe_votes = max(1, vote_count)
        log_votes = math.log10(safe_votes + 10)
        # Référence : 10,000 votes = ~4.0 en log10
        # Les films avec 1,000 votes reçoivent un boost, ceux avec 30,000 un malus
        ratio = 4.0 / log_votes
        # On applique la force du slider
        multiplier = 1.0 + (ratio - 1.0) * (discovery_weight * 0.35)
        return max(0.65, min(1.45, multiplier))

    def recommend(
        self,
        reference_id: int,
        top_n: int = 5,
        weights: Optional[Dict[str, float]] = None,
        discovery_slider: float = 0.3,
    ) -> List[Dict[str, Any]]:
        """
        Génère les recommandations pour un film de référence.

        Args:
            reference_id: ID TMDb du film
            top_n: Nombre de recommandations souhaitées
            weights: Dictionnaire des pondérations (genre, atmosphere, visual, era, pacing)
            discovery_slider: 0.0 (neutre) à 1.0 (forte prime à la découverte)

        Returns:
            Liste ordonnée de dictionnaires avec le score et l'explication "Pourquoi ce film ?".
        """
        ref_key = str(reference_id)
        if ref_key not in self.movies:
            raise KeyError(f"Film ID {reference_id} non trouvé dans la base.")

        ref = self.movies[ref_key]
        ref_vecs = ref["vectors"]

        # Poids par défaut
        w = {
            "genre": 1.0,
            "atmosphere": 1.5,
            "visual": 1.2,
            "era": 0.5,
            "pacing": 0.8,
        }
        if weights:
            w.update(weights)

        total_weight = sum(w.values())
        results = []

        for mid, candidate in self.movies.items():
            if mid == ref_key:
                continue  # On ne se recommande pas soi-même

            c_vecs = candidate["vectors"]

            # 1. Calcul des similarités composante par composante
            sim_genre = self._cosine_sim(ref_vecs["genre"], c_vecs["genre"])
            sim_atmo  = self._cosine_sim(ref_vecs["atmosphere"], c_vecs["atmosphere"])
            sim_vis   = self._cosine_sim(ref_vecs["visual"], c_vecs["visual"])
            sim_era   = self._scalar_sim(ref_vecs["era"][0], c_vecs["era"][0])
            sim_pace  = self._scalar_sim(ref_vecs["pacing"][0], c_vecs["pacing"][0])

            # 2. Similarité composite pondérée
            base_similarity = (
                w["genre"] * sim_genre +
                w["atmosphere"] * sim_atmo +
                w["visual"] * sim_vis +
                w["era"] * sim_era +
                w["pacing"] * sim_pace
            ) / total_weight

            # 3. Facteur de découverte
            discovery_factor = self.compute_discovery_factor(
                candidate.get("vote_count", 5000), discovery_slider
            )

            # 4. Score final normalisé dans [0, 1]
            final_score = min(1.0, base_similarity * discovery_factor)

            # 5. Explications dynamiques "Pourquoi ce film ?"
            sub_scores = {
                "Ambiance": sim_atmo,
                "Esthétique Visuelle": sim_vis,
                "Rythme": sim_pace,
                "Genres": sim_genre,
                "Époque": sim_era
            }
            # Trouve les 2 composantes les plus fortes
            sorted_reasons = sorted(sub_scores.items(), key=lambda x: x[1], reverse=True)
            top_reasons = [
                f"{name} très proche ({int(val * 100)}%)"
                for name, val in sorted_reasons[:2] if val >= 0.50
            ]
            
            common_tags = list(set(ref["atmosphere_tags"]) & set(candidate["atmosphere_tags"]))
            explanation = " • ".join(top_reasons)
            if common_tags:
                explanation += f" • Tags partagés : {', '.join(common_tags[:3])}"
            if discovery_factor > 1.05 and discovery_slider > 0.2:
                explanation += " • 💎 Pépite méconnue mise en avant"

            results.append({
                "id": candidate["id"],
                "title": candidate["title"],
                "year": candidate["year"],
                "vote_average": candidate["vote_average"],
                "vote_count": candidate["vote_count"],
                "genres": candidate["genres"],
                "atmosphere_tags": candidate["atmosphere_tags"],
                "pacing": candidate["pacing"],
                "score": round(final_score, 4),
                "base_similarity": round(base_similarity, 4),
                "discovery_factor": round(discovery_factor, 2),
                "sub_scores": {k: round(v, 3) for k, v in sub_scores.items()},
                "explanation": explanation
            })

        # Trie par score décroissant
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_n]
