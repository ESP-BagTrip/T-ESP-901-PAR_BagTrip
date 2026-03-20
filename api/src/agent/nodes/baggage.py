"""Baggage advisor node — suggests packing list based on real weather + activities."""

from __future__ import annotations

import json

from src.agent.prompts import BAGGAGE_PROMPT
from src.agent.state import TripPlanState
from src.services.llm_service import LLMService
from src.utils.logger import logger


async def baggage_node(state: TripPlanState) -> dict:
    """Suggest packing items grounded by real weather data."""
    logger.info("=== Baggage Advisor Node ===")

    dest = state.get("selected_destination", {})
    weather = state.get("weather_data", {})
    activities = state.get("activities", [])

    parts = [
        f"Destination: {dest.get('city', 'Unknown')}, {dest.get('country', '')}",
    ]

    if weather:
        parts.append(f"Real weather data: {json.dumps(weather)}")

    if state.get("duration_days"):
        parts.append(f"Trip duration: {state['duration_days']} days")

    if activities:
        activity_titles = [a.get("title", "") for a in activities[:8]]
        parts.append(f"Planned activities: {', '.join(activity_titles)}")

    if state.get("companions"):
        parts.append(f"Traveling with: {state['companions']}")
    if state.get("constraints"):
        parts.append(f"Constraints: {state['constraints']}")
    if state.get("travel_style"):
        parts.append(f"Travel style: {state['travel_style']}")

    user_prompt = "\n".join(parts)

    # Direct LLM call (weather data already fetched by destination research)
    llm = LLMService()
    try:
        result = await llm.acall_llm(BAGGAGE_PROMPT, user_prompt)
        items = result.get("items", [])
    except Exception as e:
        logger.error("Baggage advisor LLM call failed", {"error": str(e)})
        items = _default_baggage_items()

    logger.info("Baggage advisor complete", {"count": len(items)})

    return {
        "baggage_items": items,
        "events": [
            {
                "event": "baggage",
                "data": {"items": items},
            },
        ],
    }


def _default_baggage_items() -> list[dict]:
    """Fallback baggage items if LLM fails."""
    return [
        {"name": "Passeport", "quantity": 1, "category": "DOCUMENTS", "reason": "Essential travel document"},
        {"name": "Adaptateur de voyage", "quantity": 1, "category": "ELECTRONICS", "reason": "Power adapter"},
        {"name": "Crème solaire", "quantity": 1, "category": "TOILETRIES", "reason": "Sun protection"},
        {"name": "Trousse de premiers secours", "quantity": 1, "category": "HEALTH", "reason": "Emergency kit"},
        {"name": "Chargeur de téléphone", "quantity": 1, "category": "ELECTRONICS", "reason": "Keep devices charged"},
        {"name": "Vêtements de rechange", "quantity": 3, "category": "CLOTHING", "reason": "Daily wear"},
    ]
