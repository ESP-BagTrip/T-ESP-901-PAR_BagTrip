"""Unit tests for WeatherService (SMP327-021)."""

from datetime import date
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch

import pytest

from src.services.weather_service import WeatherService


def _trip(**overrides):
    base = {
        "destination_name": "Barcelona",
        "start_date": date(2027, 12, 1),
        "end_date": date(2027, 12, 10),
    }
    base.update(overrides)
    return SimpleNamespace(**base)


@pytest.mark.asyncio
async def test_get_trip_weather_resolves():
    trip = _trip()
    with (
        patch(
            "src.agent.tools.resolve_iata_code",
            new=AsyncMock(return_value={"lat": 41.0, "lon": 2.0}),
        ),
        patch(
            "src.agent.tools.get_weather",
            new=AsyncMock(
                return_value={
                    "avg_temp_c": 18,
                    "min_temp_c": 12,
                    "max_temp_c": 24,
                    "description": "Sunny",
                    "rain_probability": 10,
                    "source": "open-meteo",
                }
            ),
        ),
    ):
        result = await WeatherService.get_trip_weather(trip)

    assert result is not None
    assert result["avg_temp_c"] == 18.0
    assert result["description"] == "Sunny"
    assert result["source"] == "open-meteo"


@pytest.mark.asyncio
async def test_get_trip_weather_no_destination():
    trip = _trip(destination_name=None)
    result = await WeatherService.get_trip_weather(trip)
    assert result is None


@pytest.mark.asyncio
async def test_get_trip_weather_unresolvable_coordinates():
    trip = _trip()
    with patch(
        "src.agent.tools.resolve_iata_code", new=AsyncMock(return_value={"error": "not found"})
    ):
        result = await WeatherService.get_trip_weather(trip)
    assert result is None
