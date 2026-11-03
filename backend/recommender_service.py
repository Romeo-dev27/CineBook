"""
recommender_service.py — Service de calcul des recommandations connecté à la base SQLite

Charge les vecteurs précalculés depuis la table movie_vectors,
exécute le calcul de Similarité Cosinus Pondérée et applique le modificateur
de découverte.
"""

import math
from typing import List, Dict, Any, Optional
import numpy as np
from sqlalchemy.orm import Session
from models import Movie, MovieVector


class DatabaseRecommenderService:
    """Service de recommandation opérant directement sur la base de données SQLite."""

    @staticmethod
    def _cosine_sim(v1: List[float], v2: List[float]) -> float:
        a = np.array(v1)
        b = np.array(v2)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return float(np.dot(a, b) / (norm_a * norm_b))

    @staticmethod
    def _scalar_sim(s1: float, s2: float) -> float:
        return max(0.0, 1.0 - abs(s1 - s2))

    @staticmethod
    def compute_discovery_factor(vote_count: int, discovery_weight: float) -> float:
        if discovery_weight <= 0.0:
            return 1.0
        safe_votes = max(1, vote_count)
        log_votes = math.log10(safe_votes + 10)
        ratio = 4.0 / log_votes
        multiplier = 1.0 + (ratio - 1.0) * (discovery_weight * 0.35)
        return max(0.65, min(1.45, multiplier))

    def recommend(
        self,
        db: Session,
        reference_ids: Optional[List[int]] = None,
        reference_id: Optional[int] = None,
        top_n: int = 5,
        weights: Optional[Dict[str, float]] = None,
        discovery_slider: float = 0.3
    ) -> List[Dict[str, Any]]:
        # 1. Normaliser et résoudre les IDs cibles
        target_ids: List[int] = []
        if reference_ids:
            target_ids = list(dict.fromkeys(reference_ids))
        elif reference_id is not None:
            target_ids = [reference_id]

        if not target_ids:
            return []

        # 2. Récupère les films de référence avec leurs vecteurs
        ref_movies = (
            db.query(Movie)
            .join(Movie.feature_vector)
            .filter(Movie.id.in_(target_ids))
            .all()
        )
        if not ref_movies:
            return []

        # 3. Calcul de la moyenne mathématique (centroid average) pour créer le profil utilisateur mixte
        genre_vecs = [np.array(m.feature_vector.genre_vec, dtype=float) for m in ref_movies]
        atmo_vecs = [np.array(m.feature_vector.atmosphere_vec, dtype=float) for m in ref_movies]
        vis_vecs = [np.array(m.feature_vector.visual_vec, dtype=float) for m in ref_movies]
        era_scalars = [float(m.feature_vector.era_scalar) for m in ref_movies]
        pacing_scalars = [float(m.feature_vector.pacing_scalar) for m in ref_movies]

        mean_genre = np.mean(genre_vecs, axis=0).tolist()
        mean_atmo = np.mean(atmo_vecs, axis=0).tolist()
        mean_vis = np.mean(vis_vecs, axis=0).tolist()
        mean_era = float(np.mean(era_scalars))
        mean_pace = float(np.mean(pacing_scalars))

        # Collecte l'ensemble des tags d'atmosphère de tous les films sélectionnés
        all_ref_tags = set()
        for m in ref_movies:
            all_ref_tags.update(t.name for t in m.atmosphere_tags)

        # Poids configurés
        w = {
            "atmosphere": 1.5,
            "visual": 1.2,
            "genre": 1.0,
            "era": 0.5,
            "pacing": 0.8,
        }
        if weights:
            w.update(weights)
        total_weight = sum(w.values())

        # 4. Récupère tous les autres films candidats (excluant TOUS les films sélectionnés)
        candidates = (
            db.query(Movie)
            .join(Movie.feature_vector)
            .filter(~Movie.id.in_(target_ids))
            .all()
        )

        results = []

        for cand in candidates:
            c_vec = cand.feature_vector
            if not c_vec:
                continue

            sim_genre = self._cosine_sim(mean_genre, c_vec.genre_vec)
            sim_atmo  = self._cosine_sim(mean_atmo, c_vec.atmosphere_vec)
            sim_vis   = self._cosine_sim(mean_vis, c_vec.visual_vec)
            sim_era   = self._scalar_sim(mean_era, c_vec.era_scalar)
            sim_pace  = self._scalar_sim(mean_pace, c_vec.pacing_scalar)

            base_similarity = (
                w["genre"] * sim_genre +
                w["atmosphere"] * sim_atmo +
                w["visual"] * sim_vis +
                w["era"] * sim_era +
                w["pacing"] * sim_pace
            ) / total_weight

            discovery_factor = self.compute_discovery_factor(cand.vote_count, discovery_slider)
            final_score = min(1.0, base_similarity * discovery_factor)

            sub_scores = {
                "Ambiance": sim_atmo,
                "Esthétique Visuelle": sim_vis,
                "Rythme": sim_pace,
                "Genres": sim_genre,
                "Époque": sim_era,
            }
            sorted_reasons = sorted(sub_scores.items(), key=lambda x: x[1], reverse=True)
            top_reasons = [
                f"{name} très proche ({int(val * 100)}%)"
                for name, val in sorted_reasons[:2] if val >= 0.50
            ]

            cand_tags = [t.name for t in cand.atmosphere_tags]
            common_tags = list(all_ref_tags & set(cand_tags))

            prefix = f"Vibe mixte ({len(ref_movies)} films) • " if len(ref_movies) > 1 else ""
            explanation = prefix + " • ".join(top_reasons)
            if common_tags:
                explanation += f" • Tags partagés : {', '.join(common_tags[:3])}"
            if discovery_factor > 1.05 and discovery_slider > 0.2:
                explanation += " • 💎 Pépite méconnue mise en avant"

            results.append({
                "id": cand.id,
                "title": cand.title,
                "year": cand.year,
                "poster_path": cand.poster_path,
                "backdrop_path": cand.backdrop_path,
                "vote_average": cand.vote_average,
                "vote_count": cand.vote_count,
                "genres": [g.name for g in cand.genres],
                "atmosphere_tags": cand_tags,
                "pacing": cand.pacing,
                "score": round(final_score, 4),
                "base_similarity": round(base_similarity, 4),
                "discovery_factor": round(discovery_factor, 2),
                "sub_scores": {k: round(v, 3) for k, v in sub_scores.items()},
                "explanation": explanation
            })

        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_n]


recommender_service = DatabaseRecommenderService()
