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
            "events": [{"event": "progress", "data": {"phase": "destination_research", "message": "No destinations found, using defaults"}}],
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
