"""Activity planner node — generates contextual activities based on destination + weather."""

from __future__ import annotations

import json

from src.agent.prompts import render
from src.agent.runtime_budget import guard
from src.agent.state import TripPlanState
from src.services.llm_service import LLMService
from src.utils.logger import logger


async def activity_planner_node(state: TripPlanState) -> dict:
    """Plan activities grounded by real weather data and destination context."""
    guard(state, min_required=5.0)
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

    # Direct LLM call (no tools needed for activity planning).
    llm = LLMService()
    try:
        result = await llm.acall_llm(
            render("activity_planner", locale=state.get("locale", "en")),
            user_prompt,
        )
    except Exception as e:
        logger.error("Activity planner LLM call failed", {"error": str(e)})
        result = {}

    activities = _normalize_recommendations(result)

    logger.info(
        "Activity planner complete",
        {
            "total": len(activities),
            "by_category": _count_by_category(activities),
        },
    )

    return {
        "activities": activities,
        "events": [
            {
                "event": "activities",
                "data": {"activities": activities, "source": "llm"},
            },
        ],
    }


def _normalize_recommendations(result: dict) -> list[dict]:
    """Flatten the LLM response into a single list of activity dicts.

    SMP-324 — the prompt now returns three buckets:
        - ``activities``: dated itinerary entries (CULTURE, NATURE, ...)
        - ``meals``     : undated FOOD recommendations
        - ``transports``: undated TRANSPORT recommendations

    Modelling them as a single list keeps the persistence path
    uniform: each entry becomes one ``Activity`` row plus one
    ``BudgetItem`` so the review breakdown and the trip detail tab
    Budget agree by construction. The category drives the UI grouping
    downstream; ``suggested_day`` / ``time_of_day`` stay absent on
    undated entries so the front renders them in the dedicated
    "Restos à essayer" / "Transports utiles" sections.

    The function tolerates partial / malformed payloads: missing keys
    yield empty buckets, and any entry that already carries the
    expected category is forwarded as-is. ``result`` is typed ``dict``
    but the LLM payload is not; ``_safe_list`` below rejects anything
    that is not a list of dicts so the persistence path stays clean.
    """
    out: list[dict] = []

    for entry in _safe_list(result.get("activities")):
        out.append(entry)

    for entry in _safe_list(result.get("meals")):
        # Force the category — the prompt asks for FOOD but a stray
        # value would otherwise leak through to the BudgetItem row.
        normalized = {**entry, "category": "FOOD"}
        normalized.pop("suggested_day", None)
        normalized.pop("time_of_day", None)
        out.append(normalized)

    for entry in _safe_list(result.get("transports")):
        normalized = {**entry, "category": "TRANSPORT"}
        normalized.pop("suggested_day", None)
        normalized.pop("time_of_day", None)
        out.append(normalized)

    return out


def _safe_list(value: object) -> list[dict]:
    """Filter ``value`` down to the list-of-dicts the LLM is supposed to emit.

    The agent code is typed but the LLM payload is not, so this guard
    keeps the rest of the function arrow-free without sprinkling
    ``# type: ignore`` everywhere.
    """
    if not isinstance(value, list):
        return []
    return [entry for entry in value if isinstance(entry, dict)]


def _count_by_category(activities: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for entry in activities:
        key = str(entry.get("category") or "OTHER")
        counts[key] = counts.get(key, 0) + 1
    return counts
