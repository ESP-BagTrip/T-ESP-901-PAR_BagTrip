"""Weather forecast tool (Open-Meteo — free, no API key)."""

from __future__ import annotations

from src.config.env import settings
from src.integrations.http_client import get_http_client
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


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

    # httpx accepts a mapping of scalar values — we annotate explicitly so
    # mypy sees `str | float` rather than the default `object` it would
    # infer from mixing latitude/longitude floats with string keys.
    params: dict[str, str | float] = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
        "timezone": "auto",
    }

    try:
        client = get_http_client()
        response = await client.get(url, params=params, timeout=10.0)

        if response.status_code != 200:
            logger.error("Open-Meteo API failed", {"status": response.status_code})
            return _fallback_weather(start_date, latitude=latitude)

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
        return _fallback_weather(start_date, latitude=latitude)


def _fallback_weather(start_date: str, latitude: float | None = None) -> dict:
    """Estimate weather from latitude (climate zone) + month when Open-Meteo is unavailable.

    Climate zones by absolute latitude:
    - 55°+      subarctic   : summer 18°C / winter -5°C
    - 35-55°    temperate   : summer 25°C / winter  8°C
    - 23-35°    subtropical : summer 30°C / winter 18°C
    - <23°      tropical    : stable 28°C year-round
    """
    try:
        month = int(start_date.split("-")[1])
    except (IndexError, ValueError):
        month = 6

    # No latitude → original month-only fallback
    if latitude is None:
        if month in (6, 7, 8):
            return {
                "avg_temp_c": 25,
                "min_temp_c": 18,
                "max_temp_c": 32,
                "rain_probability": 15,
                "description": "Summer estimate",
                "source": "estimated",
            }
        if month in (12, 1, 2):
            return {
                "avg_temp_c": 5,
                "min_temp_c": -2,
                "max_temp_c": 10,
                "rain_probability": 40,
                "description": "Winter estimate",
                "source": "estimated",
            }
        if month in (3, 4, 5):
            return {
                "avg_temp_c": 15,
                "min_temp_c": 8,
                "max_temp_c": 22,
                "rain_probability": 30,
                "description": "Spring estimate",
                "source": "estimated",
            }
        return {
            "avg_temp_c": 18,
            "min_temp_c": 10,
            "max_temp_c": 25,
            "rain_probability": 25,
            "description": "Autumn estimate",
            "source": "estimated",
        }

    # Latitude-aware estimation
    abs_lat = abs(latitude)

    # Determine if it's summer in the relevant hemisphere
    # Northern hemisphere: summer = months 5-9, Southern: summer = months 11-3
    is_summer = month in (5, 6, 7, 8, 9) if latitude >= 0 else month in (11, 12, 1, 2, 3)

    # Climate zone temperatures
    if abs_lat < 23:
        # Tropical — stable year-round
        avg = 28
        temp_min, temp_max = 24, 32
        rain = 60 if is_summer else 30  # wet/dry season
        desc = "Tropical — warm and humid" if is_summer else "Tropical — warm and dry"
    elif abs_lat < 35:
        # Subtropical
        if is_summer:
            avg, temp_min, temp_max, rain = 30, 24, 36, 25
            desc = "Subtropical summer — hot"
        else:
            avg, temp_min, temp_max, rain = 18, 12, 24, 35
            desc = "Subtropical winter — mild"
    elif abs_lat < 55:
        # Temperate
        if is_summer:
            avg, temp_min, temp_max, rain = 25, 18, 32, 20
            desc = "Temperate summer — warm"
        else:
            avg, temp_min, temp_max, rain = 8, 2, 14, 40
            desc = "Temperate winter — cool"
    else:
        # Subarctic
        if is_summer:
            avg, temp_min, temp_max, rain = 18, 12, 24, 30
            desc = "Subarctic summer — mild"
        else:
            avg, temp_min, temp_max, rain = -5, -12, 2, 35
            desc = "Subarctic winter — cold"

    return {
        "avg_temp_c": avg,
        "min_temp_c": temp_min,
        "max_temp_c": temp_max,
        "rain_probability": rain,
        "description": desc,
        "source": "estimated_climate_zone",
    }


WEATHER_TOOLS: dict[str, dict] = {
    "get_weather": {
        "fn": get_weather,
        "description": 'Get weather forecast for a location and date range. Input: {"latitude": 48.85, "longitude": 2.35, "start_date": "2025-07-01", "end_date": "2025-07-08"}',
        "parameters": {
            "latitude": "float (required)",
            "longitude": "float (required)",
            "start_date": "string (required) — YYYY-MM-DD",
            "end_date": "string (required) — YYYY-MM-DD",
        },
    },
}
