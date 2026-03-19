"""Tool wrappers for agent nodes — Amadeus + Open-Meteo."""

from __future__ import annotations

import asyncio

import httpx

from src.config.env import settings
from src.integrations.amadeus.client import amadeus_client
from src.integrations.amadeus.types import (
    FlightOfferSearchQuery,
    HotelListSearchQuery,
    HotelOffersSearchQuery,
    LocationKeywordSearchQuery,
)
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger

# Semaphore to limit concurrent Amadeus API calls (rate-limit protection).
_amadeus_semaphore = asyncio.Semaphore(3)


# ---------------------------------------------------------------------------
# resolve_iata_code
# ---------------------------------------------------------------------------

async def resolve_iata_code(city_name: str) -> dict:
    """Resolve a city name to its IATA airport code via Amadeus.

    Returns: {"iata": "CDG", "city": "Paris", "country": "France",
              "lat": 49.0, "lon": 2.55}
    """
    cache_key_params = {"city_name": city_name}
    cached = idempotency_cache.get("resolve_iata_code", cache_key_params)
    if cached is not None:
        return cached

    try:
        async with _amadeus_semaphore:
            locations = await amadeus_client.search_locations_by_keyword(
                LocationKeywordSearchQuery(subType="CITY,AIRPORT", keyword=city_name)
            )
        if not locations:
            return {"error": f"No IATA code found for '{city_name}'"}

        loc = locations[0]
        result = {
            "iata": loc.iataCode or loc.address.cityCode,
            "city": loc.address.cityName,
            "country": loc.address.countryName,
            "lat": loc.geoCode.latitude,
            "lon": loc.geoCode.longitude,
        }
        idempotency_cache.set("resolve_iata_code", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("resolve_iata_code failed", {"city": city_name, "error": str(e)})
        return {"error": f"Amadeus location search failed: {e}"}


# ---------------------------------------------------------------------------
# search_real_flights
# ---------------------------------------------------------------------------

async def search_real_flights(
    origin: str,
    destination: str,
    date: str,
    return_date: str | None = None,
    adults: int = 1,
) -> dict:
    """Search real flight prices via Amadeus.

    Returns: {"flights": [...], "cheapest": <price>, "currency": "EUR"}
    """
    cache_key_params = {
        "origin": origin,
        "destination": destination,
        "date": date,
        "return_date": return_date,
        "adults": adults,
    }
    cached = idempotency_cache.get("search_real_flights", cache_key_params)
    if cached is not None:
        return cached

    try:
        async with _amadeus_semaphore:
            response = await amadeus_client.search_flight_offers(
                FlightOfferSearchQuery(
                    originLocationCode=origin,
                    destinationLocationCode=destination,
                    departureDate=date,
                    adults=adults,
                    returnDate=return_date,
                    max=5,
                    currencyCode="EUR",
                )
            )

        flights = []
        for offer in response.data[:5]:
            seg = offer.itineraries[0].segments[0] if offer.itineraries else None
            flights.append({
                "airline": offer.validatingAirlineCodes[0] if offer.validatingAirlineCodes else "??",
                "price": float(offer.price.grandTotal),
                "currency": offer.price.currency,
                "departure": seg.departure.at if seg else "",
                "arrival": seg.arrival.at if seg else "",
                "duration": offer.itineraries[0].duration if offer.itineraries else "",
            })

        cheapest = min((f["price"] for f in flights), default=0)
        result = {
            "flights": flights,
            "cheapest": cheapest,
            "currency": "EUR",
            "source": "amadeus",
        }
        idempotency_cache.set("search_real_flights", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("search_real_flights failed", {"error": str(e)})
        return {"error": f"Amadeus flight search failed: {e}", "source": "error"}


# ---------------------------------------------------------------------------
# search_real_hotels
# ---------------------------------------------------------------------------

async def search_real_hotels(
    city_code: str,
    check_in: str,
    check_out: str,
    adults: int = 1,
) -> dict:
    """Search real hotel prices via Amadeus.

    Returns: {"hotels": [...], "source": "amadeus"}
    """
    cache_key_params = {
        "city_code": city_code,
        "check_in": check_in,
        "check_out": check_out,
        "adults": adults,
    }
    cached = idempotency_cache.get("search_real_hotels", cache_key_params)
    if cached is not None:
        return cached

    try:
        # Step 1: Get hotel list for the city
        async with _amadeus_semaphore:
            hotel_list = await amadeus_client.search_hotel_list(
                HotelListSearchQuery(cityCode=city_code, ratings="3,4,5")
            )

        if not hotel_list.data:
            return {"hotels": [], "source": "amadeus", "note": "No hotels found"}

        # Take first 10 hotel IDs for offers search
        hotel_ids = [h.hotelId for h in hotel_list.data[:10]]

        # Step 2: Get offers for those hotels
        async with _amadeus_semaphore:
            offers_response = await amadeus_client.search_hotel_offers(
                HotelOffersSearchQuery(
                    hotelIds=",".join(hotel_ids),
                    adults=adults,
                    checkInDate=check_in,
                    checkOutDate=check_out,
                    currency="EUR",
                )
            )

        hotels = []
        for item in offers_response.data:
            hotel_info = item.hotel
            if item.offers:
                offer = item.offers[0]
                price = float(offer.price.total) if offer.price and offer.price.total else None
                hotels.append({
                    "name": hotel_info.get("name", "Unknown Hotel"),
                    "hotel_id": hotel_info.get("hotelId", ""),
                    "price_total": price,
                    "currency": offer.price.currency if offer.price else "EUR",
                    "check_in": offer.checkInDate,
                    "check_out": offer.checkOutDate,
                    "source": "amadeus",
                })

        result = {"hotels": hotels, "source": "amadeus"}
        idempotency_cache.set("search_real_hotels", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("search_real_hotels failed", {"error": str(e)})
        return {"hotels": [], "source": "error", "error": str(e)}


# ---------------------------------------------------------------------------
# get_weather  (Open-Meteo — free, no API key)
# ---------------------------------------------------------------------------

async def get_weather(
    latitude: float,
    longitude: float,
    start_date: str,
    end_date: str,
) -> dict:
    """Get weather forecast/climate data from Open-Meteo.

    Returns: {"avg_temp_c": 22, "min_temp_c": 15, "max_temp_c": 28,
              "rain_probability": 20, "description": "Warm and sunny"}
    """
    cache_key_params = {
        "lat": latitude,
        "lon": longitude,
        "start": start_date,
        "end": end_date,
    }
    cached = idempotency_cache.get("get_weather", cache_key_params)
    if cached is not None:
        return cached

    base_url = settings.OPEN_METEO_BASE_URL
    url = f"{base_url}/v1/forecast"

    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
        "timezone": "auto",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, params=params)

        if response.status_code != 200:
            logger.error("Open-Meteo API failed", {"status": response.status_code})
            return _fallback_weather(start_date)

        data = response.json()
        daily = data.get("daily", {})

        temps_max = daily.get("temperature_2m_max", [])
        temps_min = daily.get("temperature_2m_min", [])
        rain_probs = daily.get("precipitation_probability_max", [])

        avg_max = sum(temps_max) / len(temps_max) if temps_max else 20
        avg_min = sum(temps_min) / len(temps_min) if temps_min else 10
        avg_temp = (avg_max + avg_min) / 2
        avg_rain = sum(rain_probs) / len(rain_probs) if rain_probs else 30

        # Determine season from actual temperature
        if avg_temp >= 25:
            description = "Hot — summer conditions"
        elif avg_temp >= 15:
            description = "Warm and pleasant"
        elif avg_temp >= 5:
            description = "Cool — spring/autumn conditions"
        else:
            description = "Cold — winter conditions"

        result = {
            "avg_temp_c": round(avg_temp, 1),
            "min_temp_c": round(avg_min, 1),
            "max_temp_c": round(avg_max, 1),
            "rain_probability": round(avg_rain),
            "description": description,
            "source": "open-meteo",
        }
        idempotency_cache.set("get_weather", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("get_weather failed", {"error": str(e)})
        return _fallback_weather(start_date)


def _fallback_weather(start_date: str) -> dict:
    """Guess weather from month when Open-Meteo is unavailable."""
    try:
        month = int(start_date.split("-")[1])
    except (IndexError, ValueError):
        month = 6

    if month in (6, 7, 8):
        return {"avg_temp_c": 25, "min_temp_c": 18, "max_temp_c": 32, "rain_probability": 15, "description": "Summer estimate", "source": "estimated"}
    if month in (12, 1, 2):
        return {"avg_temp_c": 5, "min_temp_c": -2, "max_temp_c": 10, "rain_probability": 40, "description": "Winter estimate", "source": "estimated"}
    if month in (3, 4, 5):
        return {"avg_temp_c": 15, "min_temp_c": 8, "max_temp_c": 22, "rain_probability": 30, "description": "Spring estimate", "source": "estimated"}
    return {"avg_temp_c": 18, "min_temp_c": 10, "max_temp_c": 25, "rain_probability": 25, "description": "Autumn estimate", "source": "estimated"}


# ---------------------------------------------------------------------------
# Tool registry (name → callable + description for ReAct prompts)
# ---------------------------------------------------------------------------

TOOL_REGISTRY: dict[str, dict] = {
    "resolve_iata_code": {
        "fn": resolve_iata_code,
        "description": "Resolve a city name to its IATA airport code. Input: {\"city_name\": \"Paris\"}",
        "parameters": {"city_name": "string (required) — city name to resolve"},
    },
    "search_real_flights": {
        "fn": search_real_flights,
        "description": "Search real flight prices via Amadeus. Input: {\"origin\": \"CDG\", \"destination\": \"BCN\", \"date\": \"2025-07-01\", \"return_date\": \"2025-07-08\", \"adults\": 1}",
        "parameters": {
            "origin": "string (required) — origin IATA code",
            "destination": "string (required) — destination IATA code",
            "date": "string (required) — departure date YYYY-MM-DD",
            "return_date": "string (optional) — return date YYYY-MM-DD",
            "adults": "int (optional, default 1)",
        },
    },
    "search_real_hotels": {
        "fn": search_real_hotels,
        "description": "Search real hotel prices via Amadeus. Input: {\"city_code\": \"PAR\", \"check_in\": \"2025-07-01\", \"check_out\": \"2025-07-08\", \"adults\": 1}",
        "parameters": {
            "city_code": "string (required) — IATA city code",
            "check_in": "string (required) — YYYY-MM-DD",
            "check_out": "string (required) — YYYY-MM-DD",
            "adults": "int (optional, default 1)",
        },
    },
    "get_weather": {
        "fn": get_weather,
        "description": "Get weather forecast for a location and date range. Input: {\"latitude\": 48.85, \"longitude\": 2.35, \"start_date\": \"2025-07-01\", \"end_date\": \"2025-07-08\"}",
        "parameters": {
            "latitude": "float (required)",
            "longitude": "float (required)",
            "start_date": "string (required) — YYYY-MM-DD",
            "end_date": "string (required) — YYYY-MM-DD",
        },
    },
}
