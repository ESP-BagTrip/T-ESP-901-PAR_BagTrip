"""Client AirLabs pour les informations de vol en temps réel."""

from src.config.env import settings
from src.integrations.circuit_breaker import CircuitBreaker, CircuitOpenError
from src.integrations.distributed_cache import DistributedCache
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_CACHE_TTL = 300  # 5 minutes
# Shared across workers via Redis (falls back to per-process memory).
_cache = DistributedCache("airlabs", ttl_seconds=_CACHE_TTL)

# AirLabs is a best-effort enrichment provider: when it is down we already
# swallow-and-warn, so the breaker just lets us skip the network round-trip.
_breaker = CircuitBreaker("airlabs")


class AirLabsClient:
    """Client pour l'API AirLabs."""

    BASE_URL = "https://airlabs.co/api/v9"

    @staticmethod
    async def lookup_flight(flight_iata: str) -> dict | None:
        """Rechercher les infos d'un vol par code IATA.

        Returns None if not found or API key not configured.
        """
        if not settings.AIRLABS_API_KEY:
            return None

        code = flight_iata.upper().strip()

        cached = _cache.get(code)
        if cached is not None:
            return cached

        async def _fetch() -> dict | None:
            client = get_http_client()
            resp = await client.get(
                f"{AirLabsClient.BASE_URL}/flight",
                params={"flight_iata": code, "api_key": settings.AIRLABS_API_KEY},
                timeout=10.0,
            )
            resp.raise_for_status()
            payload = resp.json()

            response = payload.get("response")
            if not response:
                return None

            data = (
                response
                if isinstance(response, dict)
                else response[0]
                if isinstance(response, list) and response
                else None
            )
            if not data:
                return None

            _cache.set(code, data)
            return data

        try:
            # The network call runs through the breaker so repeated AirLabs
            # outages trip it OPEN and we stop paying the round-trip.
            return await _breaker.call(_fetch)
        except CircuitOpenError as e:
            logger.warn(f"AirLabs circuit open, skipping lookup for {code}: {e}")
            return None
        except Exception as e:
            logger.warn(f"AirLabs lookup failed for {code}: {e}")
            return None


airlabs_client = AirLabsClient()
