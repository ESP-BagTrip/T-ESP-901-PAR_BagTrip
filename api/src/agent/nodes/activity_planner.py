"""Activity planner node — generates contextual activities based on destination + weather."""

from __future__ import annotations

import json

from src.agent.prompts import ACTIVITY_PLANNER_PROMPT
from src.agent.state import TripPlanState
from src.services.llm_service import LLMService
from src.utils.logger import logger


async def activity_planner_node(state: TripPlanState) -> dict:
    """Plan activities grounded by real weather data and destination context."""
    logger.info("=== Activity Planner Node ===")

    dest = state.get("selected_destination", {})
    weather = state.get("weather_data", {})

    # Build context prompt (no tools needed — pure LLM with grounded context)
    parts = [
        f"Destination: {dest.get('city', 'Unknown')}, {dest.get('country', '')}",
    ]

    if weather:
        parts.append(f"Weather forecast: {json.dumps(weather)}")

    if state.get("travel_types"):
        parts.append(f"Travel preferences: {state['travel_types']}")
    if state.get("duration_days"):
        parts.append(f"Trip duration: {state['duration_days']} days")
    if state.get("companions"):
        parts.append(f"Traveling with: {state['companions']}")
    if state.get("constraints"):
        parts.append(f"Constraints: {state['constraints']}")
    if state.get("travel_style"):
        parts.append(f"Travel style: {state['travel_style']}")
    if state.get("budget_preset"):
        from src.api.ai.plan_trip_schemas import BUDGET_PRESET_RANGES

        label = BUDGET_PRESET_RANGES.get(state["budget_preset"], {}).get(
            "label", state["budget_preset"]
        )
        parts.append(f"Budget level: {label}")

    user_prompt = "\n".join(parts)

    # Direct LLM call (no tools needed for activity planning)
    llm = LLMService()
    try:
        result = await llm.acall_llm(ACTIVITY_PLANNER_PROMPT, user_prompt)
        activities = result.get("activities", [])
    except Exception as e:
        logger.error("Activity planner LLM call failed", {"error": str(e)})
        activities = []

    logger.info("Activity planner complete", {"count": len(activities)})

    return {
        "activities": activities,
        "events": [
            {
                "event": "activities",
                "data": {"activities": activities, "source": "llm"},
            },
        ],
    }
