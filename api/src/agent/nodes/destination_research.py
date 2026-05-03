"""Destination research node — resolves IATA codes, gets weather, proposes destinations."""

from __future__ import annotations

from src.agent.prompts import render
from src.agent.react_executor import react_execute
from src.agent.runtime_budget import guard
from src.agent.state import TripPlanState
from src.agent.tools import TOOL_REGISTRY
from src.services.location_resolver import ResolvedCity, resolve_city
from src.utils.logger import logger


async def destination_research_node(state: TripPlanState) -> dict:
    """Research destinations using Amadeus + Open-Meteo via ReAct tools."""
    guard(state, min_required=5.0)
    logger.info("=== Destination Research Node ===")

    locale = (state.get("locale") or "en").split("-", 1)[0].lower()[:2] or "en"
    dest_city = state.get("destination_city", "")
    dest_iata = state.get("destination_iata", "")
    if dest_city or dest_iata:
        return await _research_pre_selected_destination(state, locale)

    # Build user prompt from state
    parts = []
    if state.get("origin_city"):
        parts.append(f"Origin city: {state['origin_city']}")
    if state.get("travel_types"):
        parts.append(f"Travel preferences: {state['travel_types']}")
    if state.get("budget_preset"):
        parts.append(f"Budget: {state['budget_preset']}")
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
        agent_instruction=render("destination_research", locale=state.get("locale", "en")),
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


async def _research_pre_selected_destination(state: TripPlanState, locale: str) -> dict:
    """Hydrate state for a destination already chosen at wizard step 3.

    Skips the ReAct executor entirely. The previous implementation used
    the legacy offline-only ``resolve_iata_code`` tool, which silently
    returned an empty IATA for any localized city name (the SMP-324
    Singapour bug). We now route through the unified ``resolve_city``
    cascade so localized inputs ("Singapour", "Lisbonne", "Pékin", ...)
    succeed without falling back to a downstream LLM lookup.

    Inputs honored:
        - ``destination_iata``: trusted as-is and used to look up coords
          via the offline aviation dataset (no network round-trip).
        - ``destination_city``: passed to ``resolve_city`` with the user
          locale; the resolver's cascade fills in IATA + coords +
          country when only the city is known.

    Failure mode: if both inputs are present but neither resolves, the
    node still emits the destination event with whatever fields it has
    so the SSE consumer doesn't stall, but logs an explicit warning so
    operators can spot the regression.
    """
    dest_city = state.get("destination_city", "")
    dest_iata = state.get("destination_iata", "")
    logger.info(
        "Using pre-selected destination",
        {"city": dest_city, "iata": dest_iata, "locale": locale},
    )

    resolved = await _resolve_destination(dest_iata, dest_city, locale)
    iata = resolved.iata if resolved else dest_iata
    lat = resolved.latitude if resolved else 0.0
    lon = resolved.longitude if resolved else 0.0
    city = resolved.city if resolved else dest_city
    country = resolved.country if resolved else ""

    weather = await _fetch_weather(state, lat, lon, city)

    selected = {
        "city": city,
        "country": country,
        "iata": iata,
        "weather": weather,
    }

    origin_iata = await _resolve_origin_iata(state, locale)

    return {
        "destinations": [selected],
        "origin_iata": origin_iata,
        "selected_destination": {
            "city": city,
            "country": country,
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


async def _resolve_destination(iata: str, city: str, locale: str) -> ResolvedCity | None:
    """Try IATA-first then city-first; return whichever resolves."""
    if iata:
        resolved = await resolve_city(iata, locale=locale)
        if resolved:
            return resolved
    if city:
        resolved = await resolve_city(city, locale=locale)
        if resolved:
            return resolved
    if iata or city:
        logger.warn(
            "destination_research: pre-selected destination did not resolve",
            {"iata": iata, "city": city, "locale": locale},
        )
    return None


async def _fetch_weather(state: TripPlanState, lat: float, lon: float, city: str) -> dict:
    """Fetch weather from the existing tool registry; degrade silently."""
    weather_tool = TOOL_REGISTRY.get("get_weather")
    departure_date = state.get("departure_date") or ""
    return_date = state.get("return_date") or departure_date
    if not (weather_tool and lat and lon and departure_date):
        return {}
    try:
        result = await weather_tool["fn"](
            latitude=lat,
            longitude=lon,
            start_date=departure_date,
            end_date=return_date,
        )
        return result if isinstance(result, dict) else {}
    except Exception as exc:
        logger.error(
            "destination_research: get_weather failed",
            {"city": city, "error": str(exc)},
        )
        return {}


async def _resolve_origin_iata(state: TripPlanState, locale: str) -> str:
    """Resolve the origin IATA from the user's typed city via the cascade."""
    origin_city = state.get("origin_city")
    if not origin_city:
        return ""
    resolved = await resolve_city(origin_city, locale=locale)
    if resolved is None:
        logger.warn(
            "destination_research: origin resolve missed",
            {"origin_city": origin_city, "locale": locale},
        )
        return ""
    return resolved.iata
