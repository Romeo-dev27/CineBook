"""
watch_providers_service.py — Service de récupération et mise en cache des plateformes de streaming (TMDb Watch Providers)

Permet d'obtenir pour chaque film les plateformes SVOD sur lesquelles il est disponible (ex: Netflix, Amazon Prime Video, Disney+, Apple TV+, etc.) pour un pays donné (défaut : France 'FR').
"""

import os
import json
import urllib.request
from pathlib import Path
from typing import List, Dict, Any, Optional

# Répertoires
ROOT_DIR = Path(__file__).resolve().parent.parent
LOCAL_DATA_DIR = Path(__file__).resolve().parent / "data"
ROOT_DATA_DIR = ROOT_DIR / "data_pipeline" / "data"

TMDB_API_KEY = os.getenv("TMDB_API_KEY", "")
DEFAULT_COUNTRY = "FR"


class WatchProvidersService:
    """Service gérant la détection et la mise en cache des plateformes de streaming TMDb."""

    def __init__(self):
        self._cache: Dict[str, Dict[str, List[Dict[str, Any]]]] = {}
        self._load_local_cache()

    def _load_local_cache(self) -> None:
        """Charge le cache local des 142 films depuis le fichier JSON s'il existe."""
        for cache_path in [LOCAL_DATA_DIR / "watch_providers.json", ROOT_DATA_DIR / "watch_providers.json"]:
            if cache_path.exists():
                try:
                    data = json.loads(cache_path.read_text(encoding="utf-8"))
                    for mid_str, provs in data.items():
                        if mid_str not in self._cache:
                            self._cache[mid_str] = {}
                        self._cache[mid_str][DEFAULT_COUNTRY] = provs
                    break
                except Exception:
                    pass

    def get_providers_for_movie(self, movie_id: int, country: str = DEFAULT_COUNTRY) -> List[Dict[str, Any]]:
        """
        Retourne la liste des plateformes de streaming pour un film et un pays donnés.
        Consulte le cache mémoire -> cache disque -> appel live TMDb.
        """
        mid_str = str(movie_id)
        country_code = country.upper()

        if mid_str in self._cache and country_code in self._cache[mid_str]:
            return self._cache[mid_str][country_code]

        # Appel live à l'API TMDb Watch Providers
        live_providers = self._fetch_from_tmdb(movie_id, country_code)

        if mid_str not in self._cache:
            self._cache[mid_str] = {}
        self._cache[mid_str][country_code] = live_providers

        return live_providers

    def get_providers_for_movies(self, movie_ids: List[int], country: str = DEFAULT_COUNTRY) -> Dict[int, List[Dict[str, Any]]]:
        """Retourne un dictionnaire {movie_id: [providers]} pour une liste de films."""
        result: Dict[int, List[Dict[str, Any]]] = {}
        for mid in movie_ids:
            result[mid] = self.get_providers_for_movie(mid, country)
        return result

    def movie_matches_provider(self, movie_id: int, provider_query: Optional[str], country: str = DEFAULT_COUNTRY) -> bool:
        """
        Vérifie si un film est disponible sur la plateforme demandée.
        Si provider_query est vide, None ou 'Tous'/'All', retourne True.
        """
        if not provider_query:
            return True
        query = provider_query.strip().lower()
        if query in ("", "tous", "all", "tout"):
            return True

        providers = self.get_providers_for_movie(movie_id, country)
        for p in providers:
            p_name = p.get("name", "").lower()
            # Correspondance souple
            if query in p_name or p_name in query:
                return True
            if "prime" in query and ("prime" in p_name or "amazon" in p_name):
                return True
            if "apple" in query and "apple" in p_name:
                return True
            if "disney" in query and "disney" in p_name:
                return True
        return False

    def _fetch_from_tmdb(self, movie_id: int, country: str) -> List[Dict[str, Any]]:
        """Effectue une requête HTTP sécurisée vers l'endpoint TMDb Watch Providers."""
        if not TMDB_API_KEY:
            return []

        url = f"https://api.themoviedb.org/3/movie/{movie_id}/watch/providers?api_key={TMDB_API_KEY}"
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "CineBook-FastAPI/1.0",
                "Accept": "application/json"
            }
        )

        try:
            with urllib.request.urlopen(req, timeout=3.0) as resp:
                data = json.loads(resp.read().decode("utf-8"))

            results = data.get("results", {})
            country_data = results.get(country, {})

            # 1. Priorité au streaming sur abonnement (flatrate)
            raw_providers = list(country_data.get("flatrate", []))
            # 2. Si aucun abonnement, vérifier gratuit (free) ou avec pub (ads)
            if not raw_providers:
                raw_providers = list(country_data.get("free", []) or country_data.get("ads", []))

            clean_providers: List[Dict[str, Any]] = []
            seen_names = set()

            for p in raw_providers:
                name = p.get("provider_name", "")
                # Normalisation des variantes de chaînes
                clean_name = name
                for suffix in [" Standard with Ads", " with Ads", " Amazon Channel", " Apple TV Channel"]:
                    if suffix in clean_name:
                        clean_name = clean_name.replace(suffix, "")

                if clean_name in seen_names:
                    continue
                seen_names.add(clean_name)

                clean_providers.append({
                    "id": p.get("provider_id", 0),
                    "name": clean_name,
                    "logo_path": p.get("logo_path")
                })

            # 3. Prise en compte d'Apple TV (souvent répertorié en buy/rent en France)
            if not any("apple" in name.lower() for name in seen_names):
                buy_rent = country_data.get("buy", []) + country_data.get("rent", [])
                for p in buy_rent:
                    p_name = p.get("provider_name", "")
                    if "Apple TV" in p_name:
                        clean_providers.append({
                            "id": p.get("provider_id", 2),
                            "name": "Apple TV",
                            "logo_path": p.get("logo_path", "/qdEGArH3lKfFnAtYXMkSYk5wxuG.png")
                        })
                        break

            return clean_providers
        except Exception:
            return []


# Instance singleton utilisable dans les routes et services
watch_providers_service = WatchProvidersService()
