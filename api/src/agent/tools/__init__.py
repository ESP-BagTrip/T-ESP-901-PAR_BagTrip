"""Tool wrappers for agent nodes — Amadeus + Open-Meteo + offline aviation data."""

from __future__ import annotations

from src.agent.tools.flights import FLIGHT_TOOLS, search_real_flights
from src.agent.tools.hotels import HOTEL_TOOLS, search_real_hotels
from src.agent.tools.locations import LOCATION_TOOLS, resolve_iata_code
from src.agent.tools.weather import WEATHER_TOOLS, _fallback_weather, get_weather

# ---------------------------------------------------------------------------
# Tool registry (name → callable + description for ReAct prompts)
# ---------------------------------------------------------------------------

TOOL_REGISTRY: dict[str, dict] = {
    **LOCATION_TOOLS,
    **FLIGHT_TOOLS,
    **HOTEL_TOOLS,
    **WEATHER_TOOLS,
}

__all__ = [
    "TOOL_REGISTRY",
    "_fallback_weather",
    "get_weather",
    "resolve_iata_code",
    "search_real_flights",
    "search_real_hotels",
]
