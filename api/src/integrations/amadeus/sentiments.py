"""Amadeus Hotel Sentiments integration.

Wraps ``GET /v2/e-reputation/hotel-sentiments``. Used to enrich hotel
suggestions with verified Amadeus rating axes (sleep, location, service,
value, …) so we can render trustworthy badges next to a hotel without
relying on LLM-fabricated review summaries.
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
from .types import HotelSentiment, HotelSentimentSearchQuery


@amadeus_retry
async def search_hotel_sentiments(
    query: HotelSentimentSearchQuery,
) -> list[HotelSentiment]:
    """Fetch Amadeus sentiment for up to 3 hotel IDs.

    The endpoint accepts ``hotelIds`` as a comma-separated list. Amadeus
    documents an upper bound of 3 IDs per call — the Pydantic schema
    enforces it so callers chunk their lookups deliberately rather than
    hitting a 400 at runtime.
    """
    logger.debug("amadeus.sentiments: searching", {"hotelIds": query.hotelIds})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v2/e-reputation/hotel-sentiments"
    params = {"hotelIds": ",".join(query.hotelIds)}

    try:
        client = get_http_client()
        response = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )
    except httpx.HTTPError as error:
        logger.error("amadeus.sentiments: connection failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "hotel sentiment search")
        return []  # pragma: no cover

    if response.status_code != 200:
        logger.error(
            "amadeus.sentiments: non-200",
            {"status": response.status_code, "data": response.text[:500]},
        )
        raise_for_amadeus_status(response, "hotel sentiment search")

    data = response.json()
    raw = data.get("data", [])
    sentiments = [HotelSentiment(**item) for item in raw]

    logger.info(
        "amadeus.sentiments: search completed",
        {"requested": len(query.hotelIds), "returned": len(sentiments)},
    )
    return sentiments
