"""Location resolution tool — offline (no Amadeus call)."""

from __future__ import annotations

from src.integrations.aviation_data import aviation_data_service
from src.utils.logger import logger


async def resolve_iata_code(city_name: str) -> dict:
    """Resolve a city name to its IATA airport code using offline data.

    Returns: {"iata": "CDG", "city": "Paris", "country": "France",
              "lat": 49.0, "lon": 2.55}
    """
    try:
        locations = aviation_data_service.search_by_keyword(
            city_name, sub_type="CITY,AIRPORT", limit=1
        )
        if not locations:
            return {"error": f"No IATA code found for '{city_name}'"}

        loc = locations[0]
        return {
            "iata": loc.iataCode or loc.address.cityCode,
            "city": loc.address.cityName,
            "country": loc.address.countryName,
            "lat": loc.geoCode.latitude,
            "lon": loc.geoCode.longitude,
        }
    except Exception as e:
        logger.error("resolve_iata_code failed", {"city": city_name, "error": str(e)})
        return {"error": f"Location search failed: {e}"}


LOCATION_TOOLS: dict[str, dict] = {
    "resolve_iata_code": {
        "fn": resolve_iata_code,
        "description": 'Resolve a city name to its IATA airport code. Input: {"city_name": "Paris"}',
        "parameters": {"city_name": "string (required) — city name to resolve"},
    },
}
