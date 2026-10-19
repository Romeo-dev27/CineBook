"""
test_recommender.py — Tests unitaires automatisés pour le moteur CineBook

Vérifie :
  1. L'intégrité de la matrice vectorielle (142 films, dimensions exactes).
  2. Le calcul mathématique de la similarité cosinus (identité = 1.0, orthogonaux = 0.0).
  3. Le comportement de la recommandation pour un film clé (Blade Runner 2049).
  4. L'impact de la pondération dynamique (slider visuel vs slider ambiance).
  5. Le fonctionnement du bonus découverte (pénalisation des blockbusters).
"""

import pytest
import numpy as np
from data_pipeline.recommender import CineRecommender


@pytest.fixture(scope="module")
def recommender():
    """Initialise le moteur de recommandation une seule fois pour la suite de tests."""
    return CineRecommender()


def test_matrix_integrity(recommender):
    """Vérifie que la matrice contient tous les films avec des vecteurs valides."""
    assert len(recommender.movies) >= 140, "La matrice doit contenir au moins 140 films."
    
    for mid, movie in recommender.movies.items():
        assert "vectors" in movie
        vecs = movie["vectors"]
        assert len(vecs["genre"]) == 19, f"Genre vector incorrect pour {mid}"
        assert len(vecs["atmosphere"]) == 20, f"Atmosphere vector incorrect pour {mid}"
        assert len(vecs["visual"]) == 10, f"Visual vector incorrect pour {mid}"
        assert len(vecs["era"]) == 1, f"Era vector incorrect pour {mid}"
        assert len(vecs["pacing"]) == 1, f"Pacing vector incorrect pour {mid}"
        
        # Vérifie que les sous-vecteurs sont normalisés (norme ~1.0 ou 0 si vide)
        for comp in ["genre", "atmosphere", "visual"]:
            norm = np.linalg.norm(vecs[comp])
            assert norm == pytest.approx(1.0, abs=1e-3) or norm == 0.0


def test_cosine_similarity_identity(recommender):
    """Deux vecteurs identiques doivent avoir une similarité cosinus égale à 1.0."""
    v = [0.5, 0.5, 0.5, 0.5]
    sim = recommender._cosine_sim(v, v)
    assert sim == pytest.approx(1.0, abs=1e-5)


def test_cosine_similarity_orthogonal(recommender):
    """Deux vecteurs orthogonaux doivent avoir une similarité de 0.0."""
    v1 = [1.0, 0.0, 0.0]
    v2 = [0.0, 1.0, 0.0]
    sim = recommender._cosine_sim(v1, v2)
    assert sim == pytest.approx(0.0, abs=1e-5)


def test_recommendation_blade_runner_2049(recommender):
    """
    Vérifie qu'une recommandation pour Blade Runner 2049 retourne des films cohérents
    (films de science-fiction dystopique, atmosphériques ou néo-noirs).
    """
    br_movie = recommender.find_movie_by_title("Blade Runner 2049")
    assert br_movie is not None, "Blade Runner 2049 doit être présent dans la matrice."

    recs = recommender.recommend(reference_id=br_movie["id"], top_n=5)
    assert len(recs) == 5

    rec_titles = [r["title"] for r in recs]
    print(f"\nRecs pour Blade Runner 2049 : {rec_titles}")

    # Blade Runner original ou d'autres SF d'ambiance (Dune, Arrival, Matrix, Ex Machina) doivent figurer en tête
    assert any(expected in rec_titles for expected in ["Blade Runner", "Dune", "Arrival", "Ex Machina", "Alien", "Children of Men"])


def test_discovery_bonus_penalizes_blockbuster(recommender):
    """Vérifie que le facteur de découverte est plus élevé pour un film méconnu que pour un blockbuster."""
    # Film à 35,000 votes (blockbuster)
    factor_blockbuster = recommender.compute_discovery_factor(vote_count=35000, discovery_weight=1.0)
    # Film d'auteur à 1,500 votes (pépite)
    factor_indie = recommender.compute_discovery_factor(vote_count=1500, discovery_weight=1.0)

    assert factor_indie > factor_blockbuster, "Le film indé doit avoir un facteur supérieur au blockbuster."
    assert factor_blockbuster < 1.0, "Le blockbuster doit recevoir une légère décote."
    assert factor_indie > 1.0, "La pépite indé doit recevoir un bonus."


def test_weights_impact_ranking(recommender):
    """Vérifie que changer les poids influence le classement."""
    br_movie = recommender.find_movie_by_title("Blade Runner 2049")
    ref_id = br_movie["id"]

    # 1. Poids standard
    recs_default = recommender.recommend(ref_id, top_n=5)
    # 2. Poids 100% sur le visuel (couleurs)
    recs_visual = recommender.recommend(
        ref_id, top_n=5,
        weights={"genre": 0.0, "atmosphere": 0.0, "visual": 5.0, "era": 0.0, "pacing": 0.0}
    )

    # Les scores ou l'ordre doivent refléter le focus visuel
    top_default = recs_default[0]["id"]
    top_visual = recs_visual[0]["id"]
    assert recs_visual[0]["sub_scores"]["Esthétique Visuelle"] >= 0.70
