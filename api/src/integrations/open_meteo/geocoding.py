"""Open-Meteo geocoding API client.

Wraps ``GET https://geocoding-api.open-meteo.com/v1/search?name=...&language=...``.
Returns the top match (or several) with coordinates, ISO country code, and
the canonical (English) place name as ``name``.

Why this matters for the IATA resolver:

    >>> places = await search_places("Singapour", language="fr")
    >>> places[0].latitude, places[0].longitude
    (1.28967, 103.85007)
    >>> places[0].country_code
    'SG'

That coordinate pair plugs into ``airportsdata.search_nearest()`` and
yields the SIN airport. The pipeline therefore tolerates any input
language without hand-maintained FR↔EN tables.
"""

from __future__ import annotations

from dataclasses import dataclass

from src.integrations.http_client import get_http_client
from src.utils.logger import logger

_GEOCODING_BASE_URL = "https://geocoding-api.open-meteo.com"
_REQUEST_TIMEOUT_SECONDS = 5.0


@dataclass(frozen=True, slots=True)
class GeocodedPlace:
    """A single geocoding result.

    Attributes mirror the Open-Meteo response. ``name`` is the localized
    label that came back (Open-Meteo returns the queried-language version
    when one is available), while ``country`` is the canonical English
    country name and ``country_code`` is ISO 3166-1 alpha-2. Latitude /
    longitude are required (a place without coords is dropped upstream).
    """

    name: str
    latitude: float
    longitude: float
    country: str
    country_code: str
    admin1: str | None = None
    population: int | None = None


async def search_places(
    name: str,
    *,
    language: str = "en",
    count: int = 5,
) -> list[GeocodedPlace]:
    """Look up places matching ``name`` in the requested ``language``.

    Returns up to ``count`` results sorted by relevance. The Open-Meteo
    free tier is generous (no API key, no per-IP quota documented), but
    we still funnel through the shared ``http_client`` so timeouts /
    retries are consistent with the rest of the integrations layer.

    Failures (network, non-200, malformed JSON) are logged at WARNING
    and resolve to an empty list so callers degrade gracefully — the
    resolver cascade has further fallbacks below this step.
    """
    if not name or not name.strip():
        return []

    params: dict[str, str | int] = {
        "name": name.strip(),
        "count": max(1, min(count, 10)),
        "language": (language or "en").lower()[:2],
        "format": "json",
    }

    try:
        client = get_http_client()
        response = await client.get(
            f"{_GEOCODING_BASE_URL}/v1/search",
            params=params,
            timeout=_REQUEST_TIMEOUT_SECONDS,
        )
    except Exception as exc:
        logger.warn(
            "open_meteo.geocoding: request failed",
            {"name": name, "language": params["language"], "error": str(exc)},
        )
        return []

    if response.status_code != 200:
        logger.warn(
            "open_meteo.geocoding: non-200",
            {"name": name, "status": response.status_code},
        )
        return []

    try:
        payload = response.json()
    except ValueError as exc:
        logger.warn("open_meteo.geocoding: malformed JSON", {"error": str(exc)})
        return []

    raw_results = payload.get("results") or []
    places: list[GeocodedPlace] = []
    for item in raw_results:
        try:
            places.append(
                GeocodedPlace(
                    name=str(item.get("name", "")).strip(),
                    latitude=float(item["latitude"]),
                    longitude=float(item["longitude"]),
                    country=str(item.get("country", "")).strip(),
                    country_code=str(item.get("country_code", "")).upper(),
                    admin1=item.get("admin1"),
                    population=item.get("population"),
                )
            )
        except (KeyError, TypeError, ValueError):
            # Skip malformed individual entries, keep parsing the rest.
            continue

    return places
