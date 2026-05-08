"""Amadeus Points of Interest integration.

Wraps ``GET /v1/reference-data/locations/pois`` so other modules can ask
"give me sights / restaurants / shopping near these coordinates" with
localized names and Amadeus-curated tags. Replaces the previous flow
where the LLM hallucinated activity titles in long phrases — Amadeus
returns the canonical name (``"Marina Bay Sands"``) and tags
(``"resort", "casino", "shopping"``) which we surface on the cards.
"""

from __future__ import annotations

import httpx

from src.config.env import settings
from src.integrations.amadeus.errors import (
    raise_amadeus_connection_error,
    raise_for_amadeus_status,
)
from src.integrations.amadeus.retry import amadeus_retry
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

from .auth import fetch_token
from .types import Poi, PoiSearchQuery


@amadeus_retry
async def search_pois(query: PoiSearchQuery) -> list[Poi]:
    """Search Points of Interest within a radius of a coordinate.

    The endpoint accepts ``lang=fr|en|...`` and localizes both the POI
    ``name`` and the ``tags`` list. We propagate that to the caller
    untouched.

    Failures (network, 4xx, 5xx) raise the same ``AppError`` family as
    every other Amadeus integration via ``raise_for_amadeus_status``,
    so the retry decorator + global error handler handle them
    uniformly.
    """
    logger.debug("amadeus.pois: searching", {"query": query.model_dump(by_alias=True)})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations/pois"
    params = query.model_dump(by_alias=True, exclude_none=True)

    try:
        client = get_http_client()
        response = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )
    except httpx.HTTPError as error:
        logger.error("amadeus.pois: connection failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "POI search")
        return []  # pragma: no cover - raise_amadeus_connection_error never returns

    if response.status_code != 200:
        logger.error(
            "amadeus.pois: non-200",
            {"status": response.status_code, "data": response.text[:500]},
        )
        raise_for_amadeus_status(response, "POI search")

    data = response.json()
    raw_pois = data.get("data", [])
    pois = [Poi(**item) for item in raw_pois]

    logger.info(
        "amadeus.pois: search completed",
        {"latitude": query.latitude, "longitude": query.longitude, "count": len(pois)},
    )
    return pois
