"""Amadeus Tours & Activities integration.

Wraps ``GET /v1/shopping/activities``. Where POIs (commit 2) describe
*things*, activities describe *things you can book*: name, short
description, price, duration, pictures, booking link. The activity_planner
node (commit 7) consumes these directly so we never round-trip through an
LLM for activity-level copy.
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
from .types import Activity, ActivitySearchQuery


@amadeus_retry
async def search_activities(query: ActivitySearchQuery) -> list[Activity]:
    """Search bookable tours / activities within a radius of a coordinate.

    Amadeus does not expose a ``lang`` parameter on this endpoint — the
    response language follows the API account locale and the activity
    provider's data. The planner therefore treats descriptions as
    free-form text (potentially mixed locales) and falls back on the
    POI tags (which *are* localized) when it needs a chip-friendly
    label.
    """
    logger.debug("amadeus.activities: searching", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/shopping/activities"
    params = query.model_dump(exclude_none=True)

    try:
        client = get_http_client()
        response = await client.get(
            url,
            params=params,
            headers={"Authorization": f"Bearer {token}"},
            timeout=settings.REQUEST_TIMEOUT_MS / 1000,
        )
    except httpx.HTTPError as error:
        logger.error("amadeus.activities: connection failed", {"message": str(error)})
        raise_amadeus_connection_error(error, "activity search")
        return []  # pragma: no cover

    if response.status_code != 200:
        logger.error(
            "amadeus.activities: non-200",
            {"status": response.status_code, "data": response.text[:500]},
        )
        raise_for_amadeus_status(response, "activity search")

    data = response.json()
    raw = data.get("data", [])
    activities = [Activity(**item) for item in raw]

    logger.info(
        "amadeus.activities: search completed",
        {"latitude": query.latitude, "longitude": query.longitude, "count": len(activities)},
    )
    return activities
