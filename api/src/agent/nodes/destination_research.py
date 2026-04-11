"""Destination research node — resolves IATA codes, gets weather, proposes destinations."""

from __future__ import annotations

from src.agent.prompts import DESTINATION_RESEARCH_PROMPT
from src.agent.react_executor import react_execute
from src.agent.state import TripPlanState
from src.agent.tools import TOOL_REGISTRY
from src.utils.logger import logger


async def destination_research_node(state: TripPlanState) -> dict:
    """Research destinations using Amadeus + Open-Meteo via ReAct tools."""
    logger.info("=== Destination Research Node ===")

    # If the user already selected a destination, skip LLM and resolve weather only
    dest_city = state.get("destination_city", "")
    dest_iata = state.get("destination_iata", "")
    if dest_city:
        logger.info("Using pre-selected destination", {"city": dest_city, "iata": dest_iata})

        # Resolve destination geocoords (+ IATA if missing) via offline aviation data
        resolve_tool = TOOL_REGISTRY.get("resolve_iata_code")
        iata = dest_iata
        lat: float = 0.0
        lon: float = 0.0
        if resolve_tool:
            try:
                dest_result = await resolve_tool["fn"](city_name=dest_city)
                if isinstance(dest_result, dict) and "error" not in dest_result:
                    iata = iata or dest_result.get("iata", "")
                    lat = float(dest_result.get("lat") or 0)
                    lon = float(dest_result.get("lon") or 0)
            except Exception as exc:
                logger.error(
                    "destination_research: resolve_iata_code failed",
                    {"city": dest_city, "error": str(exc)},
                )

        # Get weather for the destination using the full Open-Meteo signature.
        weather: dict = {}
        weather_tool = TOOL_REGISTRY.get("get_weather")
        departure_date = state.get("departure_date") or ""
        return_date = state.get("return_date") or departure_date
        if weather_tool and lat and lon and departure_date:
            try:
                weather_result = await weather_tool["fn"](
                    latitude=lat,
                    longitude=lon,
                    start_date=departure_date,
                    end_date=return_date,
                )
                if isinstance(weather_result, dict):
                    weather = weather_result
            except Exception as exc:
                logger.error(
                    "destination_research: get_weather failed",
                    {"city": dest_city, "error": str(exc)},
                )

        selected = {
            "city": dest_city,
            "country": "",
            "iata": iata,
            "weather": weather,
        }

        # Resolve origin IATA (same tool, correct kwarg)
        origin_iata = ""
        origin_city = state.get("origin_city")
        if origin_city and resolve_tool:
            try:
                origin_result = await resolve_tool["fn"](city_name=origin_city)
                if isinstance(origin_result, dict) and "error" not in origin_result:
                    origin_iata = origin_result.get("iata", "") or ""
            except Exception as exc:
                logger.error(
                    "destination_research: origin resolve failed",
                    {"city": origin_city, "error": str(exc)},
                )

        return {
            "destinations": [selected],
            "origin_iata": origin_iata,
            "selected_destination": {
                "city": dest_city,
                "country": "",
                "iata": iata,
                "lat": lat,
                "lon": lon,
            },
            "weather_data": weather,
            "events": [
                {
                    "event": "destinations",
                    "data": {"destinations": [selected], "origin_iata": origin_iata},
                },
            ],
        }

    # Build user prompt from state
    parts = []
    if state.get("origin_city"):
        parts.append(f"Origin city: {state['origin_city']}")
    if state.get("travel_types"):
        parts.append(f"Travel preferences: {state['travel_types']}")
    if state.get("budget_range"):
        parts.append(f"Budget: {state['budget_range']}")
    if state.get("duration_days"):
        parts.append(f"Duration: {state['duration_days']} days")
    if state.get("companions"):
        parts.append(f"Traveling with: {state['companions']}")
    if state.get("departure_date"):
        parts.append(f"Departure: {state['departure_date']}")
    if state.get("return_date"):
        parts.append(f"Return: {state['return_date']}")
    if state.get("constraints"):
        parts.append(f"Constraints: {state['constraints']}")
    if state.get("travel_style"):
        parts.append(f"Travel style: {state['travel_style']}")
    if state.get("season"):
        parts.append(f"Preferred season: {state['season']}")
    if state.get("budget_preset"):
        from src.api.ai.plan_trip_schemas import BUDGET_PRESET_RANGES

        label = BUDGET_PRESET_RANGES.get(state["budget_preset"], {}).get(
            "label", state["budget_preset"]
        )
        parts.append(f"Budget level: {label}")
    if state.get("nb_travelers"):
        parts.append(f"Number of travelers: {state['nb_travelers']}")

    if not parts:
        parts.append("Suggest diverse and inspiring travel destinations.")

    user_prompt = "\n".join(parts)

    # Run ReAct loop with location + weather tools
    tool_names = ["resolve_iata_code", "get_weather"]
    result = await react_execute(
        agent_instruction=DESTINATION_RESEARCH_PROMPT,
        user_prompt=user_prompt,
        tool_names=tool_names,
        tool_registry=TOOL_REGISTRY,
    )

    destinations = result.get("destinations", [])
    origin_iata = result.get("origin_iata")

    if not destinations:
        logger.warn("Destination research returned no destinations, using fallback")
        return {
            "destinations": [],
            "selected_destination": {},
            "weather_data": {},
            "events": [
                {
                    "event": "progress",
                    "data": {
                        "phase": "destination_research",
                        "message": "No destinations found, using defaults",
                    },
                }
            ],
            "errors": ["No destinations returned by LLM"],
        }

    # Select the first destination as primary
    selected = destinations[0]
    weather = selected.get("weather", {})

    logger.info(
        "Destination research complete",
        {"count": len(destinations), "selected": selected.get("city")},
    )

    return {
        "destinations": destinations,
        "origin_iata": origin_iata or "",
        "selected_destination": {
            "city": selected.get("city", ""),
            "country": selected.get("country", ""),
            "iata": selected.get("iata", ""),
            "lat": selected.get("lat", 0),
            "lon": selected.get("lon", 0),
        },
        "weather_data": weather,
        "events": [
            {
                "event": "destinations",
                "data": {"destinations": destinations, "origin_iata": origin_iata},
            },
        ],
    }
