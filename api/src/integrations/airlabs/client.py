"""Client AirLabs pour les informations de vol en temps réel."""

import time

import httpx

from src.config.env import settings
from src.utils.logger import logger

_CACHE: dict[str, dict] = {}
_CACHE_TTL = 300  # 5 minutes


class AirLabsClient:
    """Client pour l'API AirLabs."""

    BASE_URL = "https://airlabs.co/api/v9"

    @staticmethod
    def lookup_flight(flight_iata: str) -> dict | None:
        """Rechercher les infos d'un vol par code IATA.

        Returns None if not found or API key not configured.
        """
        if not settings.AIRLABS_API_KEY:
            return None

        code = flight_iata.upper().strip()

        # Check cache
        cached = _CACHE.get(code)
        if cached and (time.time() - cached["fetched_at"]) < _CACHE_TTL:
            return cached["data"]

        try:
            resp = httpx.get(
                f"{AirLabsClient.BASE_URL}/flight",
                params={"flight_iata": code, "api_key": settings.AIRLABS_API_KEY},
                timeout=10,
            )
            resp.raise_for_status()
            payload = resp.json()

            response = payload.get("response")
            if not response:
                return None

            data = response if isinstance(response, dict) else response[0] if isinstance(response, list) and response else None
            if not data:
                return None

            # Cache
            _CACHE[code] = {"data": data, "fetched_at": time.time()}
            return data
        except Exception as e:
            logger.warn(f"AirLabs lookup failed for {code}: {e}")
            return None


airlabs_client = AirLabsClient()
