"""Location resolution tool — façade over ``services.location_resolver``.

The ReAct agent talks to this thin wrapper. All the cascade logic
(IATA passthrough → cache → airportsdata → Open-Meteo geocoding)
lives in :mod:`src.services.location_resolver` so it can be reused by
non-agent code paths (route handlers, plan acceptance, jobs).
"""

from __future__ import annotations

from src.services.location_resolver import resolve_city
from src.utils.logger import logger


async def resolve_iata_code(city_name: str) -> dict:
    """Resolve a city name to its IATA airport code via the cascade.

    Returns a dict shaped like the previous offline implementation so
    existing callers don't need to migrate at the same time:
    ``{"iata", "city", "country", "lat", "lon"}`` on success, or
    ``{"error": "..."}`` when every cascade step misses.

    The caller that needs the language-aware path (the wizard) hands
    in a localized ``city_name`` and the resolver handles it. Older
    callers that already pass an English name see no behavior change.
    """
    try:
        # The agent does not currently thread the user locale into tool
        # calls; the resolver's English-first cascade still covers
        # ASCII English inputs without an Open-Meteo round-trip, and
        # the multilingual fallback steps in only when needed.
        resolved = await resolve_city(city_name, locale="en")
    except Exception as e:  # pragma: no cover - resolver is exception-safe
        logger.error("resolve_iata_code failed", {"city": city_name, "error": str(e)})
        return {"error": f"Location search failed: {e}"}

    if resolved is None:
        return {"error": f"No IATA code found for '{city_name}'"}

    return {
        "iata": resolved.iata,
        "city": resolved.city,
        "country": resolved.country,
        "lat": resolved.latitude,
        "lon": resolved.longitude,
    }


LOCATION_TOOLS: dict[str, dict] = {
    "resolve_iata_code": {
        "fn": resolve_iata_code,
        "description": 'Resolve a city name to its IATA airport code. Input: {"city_name": "Paris"}',
        "parameters": {"city_name": "string (required) — city name to resolve"},
    },
}
