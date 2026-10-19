"""
test_auth_watchlist.py — Tests d'intégration automatisés pour l'authentification et les watchlists
"""

import pytest
import uuid
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)


def _random_email():
    return f"cineaste_{uuid.uuid4().hex[:8]}@example.com"


def test_register_and_login_flow():
    email = _random_email()
    password = "SuperPassword2026!"

    # 1. Inscription
    reg_res = client.post("/api/auth/register", json={"email": email, "password": password})
    assert reg_res.status_code == 201
    data = reg_res.json()
    assert "access_token" in data
    assert data["user"]["email"] == email.lower()
    token = data["access_token"]

    # 2. Récupération du profil avec le Bearer token
    headers = {"Authorization": f"Bearer {token}"}
    me_res = client.get("/api/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == email.lower()

    # 3. Connexion
    login_res = client.post("/api/auth/login", json={"email": email, "password": password})
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()


def test_register_duplicate_email():
    email = _random_email()
    password = "Password123!"

    client.post("/api/auth/register", json={"email": email, "password": password})
    res_dup = client.post("/api/auth/register", json={"email": email, "password": password})
    assert res_dup.status_code == 400
    assert "existe déjà" in res_dup.json()["detail"]


def test_login_invalid_credentials():
    email = _random_email()
    # Inexistant
    res = client.post("/api/auth/login", json={"email": email, "password": "wrongpassword"})
    assert res.status_code == 401


def test_unauthorized_access():
    res = client.get("/api/auth/me")
    assert res.status_code == 401

    res_wl = client.get("/api/watchlist")
    assert res_wl.status_code == 401


def test_watchlist_crud_and_isolation():
    # Créer Utilisateur 1
    u1_email = _random_email()
    res1 = client.post("/api/auth/register", json={"email": u1_email, "password": "password123"})
    token1 = res1.json()["access_token"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    # Créer Utilisateur 2
    u2_email = _random_email()
    res2 = client.post("/api/auth/register", json={"email": u2_email, "password": "password123"})
    token2 = res2.json()["access_token"]
    headers2 = {"Authorization": f"Bearer {token2}"}

    # 1. Utilisateur 1 ajoute Blade Runner 2049 (ID: 335984)
    add_res = client.post(
        "/api/watchlist",
        headers=headers1,
        json={"movie_id": 335984, "status": "to_watch", "notes": "À revoir en IMAX"}
    )
    assert add_res.status_code == 201
    item = add_res.json()
    assert item["movie_id"] == 335984
    assert item["status"] == "to_watch"
    assert "Blade Runner" in item["movie"]["title"]

    # 2. Utilisateur 1 liste sa watchlist
    list1 = client.get("/api/watchlist", headers=headers1).json()
    assert len(list1) == 1
    assert list1[0]["movie_id"] == 335984

    # 3. Isolation : Utilisateur 2 ne doit rien avoir dans sa watchlist
    list2 = client.get("/api/watchlist", headers=headers2).json()
    assert len(list2) == 0

    # 4. Utilisateur 1 met à jour le statut du film vers "watched"
    patch_res = client.patch(
        "/api/watchlist/335984",
        headers=headers1,
        json={"status": "watched", "notes": "Chef d'œuvre absolu"}
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["status"] == "watched"
    assert patch_res.json()["notes"] == "Chef d'œuvre absolu"

    # 5. Utilisateur 1 supprime le film de sa watchlist
    del_res = client.delete("/api/watchlist/335984", headers=headers1)
    assert del_res.status_code == 200

    list1_after = client.get("/api/watchlist", headers=headers1).json()
    assert len(list1_after) == 0


def test_watchlist_add_invalid_movie():
    email = _random_email()
    res = client.post("/api/auth/register", json={"email": email, "password": "password123"})
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Film inexistant
    add_res = client.post("/api/watchlist", headers=headers, json={"movie_id": 99999999})
    assert add_res.status_code == 404
