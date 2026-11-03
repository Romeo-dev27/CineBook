"""
test_api.py — Tests d'intégration automatisés pour l'API REST CineBook (FastAPI)

Vérifie :
- Les routes système (/ et /health)
- La documentation Swagger (/docs et /openapi.json)
- Les routes de consultation (/api/genres, /api/tags, /api/movies, /api/movies/{id})
- La route de recommandation (/api/recommend)
- La gestion des erreurs (404 Not Found, 422 Validation Error)
"""

import pytest
from fastapi.testclient import TestClient
try:
    from main import app
except ImportError:
    from backend.main import app

client = TestClient(app)


def test_root_endpoint():
    """Vérifie le point d'entrée racine."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "version" in data
    assert data["docs"] == "/docs"
    assert "endpoints" in data


def test_health_check():
    """Vérifie la santé de l'API et la connexion SQLite."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["database"] == "connected"
    assert data["indexed_movies"] >= 140


def test_swagger_and_openapi():
    """Vérifie l'accessibilité de la documentation Swagger et du schéma OpenAPI."""
    res_docs = client.get("/docs")
    assert res_docs.status_code == 200

    res_openapi = client.get("/openapi.json")
    assert res_openapi.status_code == 200
    schema = res_openapi.json()
    assert schema["info"]["title"] == "CineBook API"
    assert "/api/recommend" in schema["paths"]
    assert "/api/movies" in schema["paths"]


def test_get_genres():
    """Vérifie la récupération de la liste des genres."""
    response = client.get("/api/genres")
    assert response.status_code == 200
    genres = response.json()
    assert isinstance(genres, list)
    assert len(genres) >= 15
    first = genres[0]
    assert "id" in first
    assert "name" in first


def test_get_atmosphere_tags():
    """Vérifie la liste exacte des 20 tags d'atmosphère."""
    response = client.get("/api/tags")
    assert response.status_code == 200
    tags = response.json()
    assert isinstance(tags, list)
    assert len(tags) == 20
    tag_names = {t["name"] for t in tags}
    assert "dark" in tag_names
    assert "melancholic" in tag_names
    assert "cold" in tag_names


def test_get_movies_pagination():
    """Vérifie la pagination et les champs de la liste de films."""
    response = client.get("/api/movies?limit=10&skip=0")
    assert response.status_code == 200
    movies = response.json()
    assert len(movies) == 10
    first = movies[0]
    assert "id" in first
    assert "title" in first
    assert "genres" in first
    assert "atmosphere_tags" in first
    assert isinstance(first["genres"], list)
    assert isinstance(first["atmosphere_tags"], list)


def test_get_movies_search():
    """Vérifie la recherche par titre insensible à la casse et aux accents."""
    response = client.get("/api/movies?query=blade")
    assert response.status_code == 200
    movies = response.json()
    assert len(movies) >= 1
    titles = [m["title"] for m in movies]
    assert any("Blade Runner" in t for t in titles)


def test_get_movies_filter_genre():
    """Vérifie le filtrage par genre."""
    response = client.get("/api/movies?genre=Science Fiction")
    assert response.status_code == 200
    movies = response.json()
    assert len(movies) > 0
    for m in movies:
        assert any("Science Fiction" in g for g in m["genres"])


def test_get_movies_filter_tag():
    """Vérifie le filtrage par tag d'atmosphère."""
    response = client.get("/api/movies?tag=melancholic")
    assert response.status_code == 200
    movies = response.json()
    assert len(movies) > 0
    for m in movies:
        assert "melancholic" in m["atmosphere_tags"]


def test_get_movie_detail_success():
    """Vérifie les détails complets d'un film existant, y compris la palette de couleurs."""
    # 335984 = Blade Runner 2049
    response = client.get("/api/movies/335984")
    assert response.status_code == 200
    movie = response.json()
    assert movie["id"] == 335984
    assert "Blade Runner 2049" in movie["title"]
    assert "overview" in movie
    assert movie["color_palette"] is not None
    palette = movie["color_palette"]
    assert "warmth" in palette
    assert "coolness" in palette
    assert "teal_ratio" in palette
    assert "orange_ratio" in palette


def test_get_movie_detail_404():
    """Vérifie l'erreur 404 pour un film inexistant."""
    response = client.get("/api/movies/99999999")
    assert response.status_code == 404
    data = response.json()
    assert "introuvable" in data["detail"]


def test_recommend_endpoint_success():
    """Vérifie l'algorithme de recommandation via l'API REST."""
    payload = {
        "movie_id": 335984,  # Blade Runner 2049
        "top_n": 5,
        "weights": {
            "atmosphere": 2.0,
            "visual": 1.5,
            "genre": 1.0,
            "era": 0.5,
            "pacing": 0.8
        },
        "discovery_slider": 0.4
    }
    response = client.post("/api/recommend", json=payload)
    assert response.status_code == 200
    data = response.json()

    # Vérification du film de référence
    assert "reference_movie" in data
    assert data["reference_movie"]["id"] == 335984
    assert "Blade Runner 2049" in data["reference_movie"]["title"]

    # Vérification des recommandations
    recs = data["recommendations"]
    assert len(recs) == 5

    # Le film de référence ne doit pas être dans ses propres recommandations
    rec_ids = [r["id"] for r in recs]
    assert 335984 not in rec_ids

    # Vérification des attributs de recommandation
    top_rec = recs[0]
    assert "score" in top_rec
    assert "sub_scores" in top_rec
    assert "explanation" in top_rec
    assert "Ambiance" in top_rec["sub_scores"]
    assert "Esthétique Visuelle" in top_rec["sub_scores"]
    assert 0.0 <= top_rec["score"] <= 1.0
    assert len(top_rec["explanation"]) > 0


def test_recommend_endpoint_404():
    """Vérifie le code 404 si le film de référence n'existe pas."""
    payload = {
        "movie_id": 88888888,
        "top_n": 5
    }
    response = client.post("/api/recommend", json=payload)
    assert response.status_code == 404
    data = response.json()
    assert "introuvable" in data["detail"]


def test_recommend_validation_error():
    """Vérifie la validation des paramètres de requête (top_n trop élevé)."""
    payload = {
        "movie_id": 335984,
        "top_n": 100  # max autorisé = 20
    }
    response = client.post("/api/recommend", json=payload)
    assert response.status_code == 422  # Unprocessable Entity


def test_recommend_multi_seeds_blended():
    """Vérifie la recommandation multi-films (mixage mathématique de plusieurs seeds)."""
    # 335984 = Blade Runner 2049, 603 = Matrix
    payload = {
        "movie_ids": [335984, 603],
        "top_n": 5,
        "weights": {
            "atmosphere": 1.8,
            "visual": 1.5,
            "genre": 1.2,
            "era": 0.5,
            "pacing": 0.8
        },
        "discovery_slider": 0.2
    }
    response = client.post("/api/recommend", json=payload)
    assert response.status_code == 200
    data = response.json()

    # Vérification des films de référence multiples
    assert "reference_movies" in data
    assert len(data["reference_movies"]) == 2
    ref_ids = [m["id"] for m in data["reference_movies"]]
    assert 335984 in ref_ids
    assert 603 in ref_ids

    # Vérification des recommandations
    recs = data["recommendations"]
    assert len(recs) == 5

    # Aucun des films de référence ne doit être présent dans les résultats
    rec_ids = [r["id"] for r in recs]
    assert 335984 not in rec_ids
    assert 603 not in rec_ids

    # L'explication doit refléter la vibe mixte
    assert "Vibe mixte (2 films)" in recs[0]["explanation"]


def test_movie_streaming_providers():
    """Vérifie la présence et la structure des badges de streaming pour un film."""
    # 335984 = Blade Runner 2049
    response = client.get("/api/movies/335984/providers")
    assert response.status_code == 200
    providers = response.json()
    assert isinstance(providers, list)
    if providers:
        p = providers[0]
        assert "id" in p
        assert "name" in p
        assert "logo_path" in p

    # Vérification que GET /api/movies/{id} contient streaming_providers
    detail_res = client.get("/api/movies/335984")
    assert detail_res.status_code == 200
    detail = detail_res.json()
    assert "streaming_providers" in detail
    assert isinstance(detail["streaming_providers"], list)


