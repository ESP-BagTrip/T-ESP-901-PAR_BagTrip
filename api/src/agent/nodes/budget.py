"""Budget estimator node — uses real flight prices + gathered hotel/activity data."""

from __future__ import annotations

import json

from src.agent.budget import guard
from src.agent.prompts import BUDGET_PROMPT
from src.agent.react_executor import react_execute
from src.agent.state import TripPlanState
from src.agent.tools import TOOL_REGISTRY
from src.utils.logger import logger


async def budget_node(state: TripPlanState) -> dict:
    """Estimate budget using real Amadeus flight prices + aggregated data."""
    guard(state, min_required=5.0)
    logger.info("=== Budget Estimator Node ===")

    dest = state.get("selected_destination", {})
    accommodations = state.get("accommodations", [])
    activities = state.get("activities", [])

    parts = [
        f"Destination: {dest.get('city', 'Unknown')}, {dest.get('country', '')} (IATA: {dest.get('iata', '')})",
    ]

    # Include origin for flight search
    if state.get("origin_city"):
        parts.append(f"Origin city: {state['origin_city']}")

    if state.get("departure_date"):
        parts.append(f"Departure date: {state['departure_date']}")
    if state.get("return_date"):
        parts.append(f"Return date: {state['return_date']}")
    if state.get("duration_days"):
        parts.append(f"Duration: {state['duration_days']} days")
    if state.get("companions"):
        parts.append(f"Travelers: {state['companions']}")
    if state.get("budget_preset"):
        from src.api.ai.plan_trip_schemas import BUDGET_PRESET_RANGES

        label = BUDGET_PRESET_RANGES.get(state["budget_preset"], {}).get(
            "label", state["budget_preset"]
        )
        parts.append(f"Budget level: {label}")
    if state.get("nb_travelers"):
        parts.append(f"Number of travelers: {state['nb_travelers']}")

    # Include gathered data for the LLM to use
    if accommodations:
        parts.append(f"Hotel data already gathered: {json.dumps(accommodations[:3], default=str)}")
    if activities:
        total_activity_cost = sum(a.get("estimated_cost", 0) or 0 for a in activities)
        parts.append(f"Total estimated activity costs: {total_activity_cost} EUR")

    user_prompt = "\n".join(parts)

    # ReAct with flight search tool
    tool_names = ["search_real_flights", "resolve_iata_code"]
    result = await react_execute(
        agent_instruction=BUDGET_PROMPT,
        user_prompt=user_prompt,
        tool_names=tool_names,
        tool_registry=TOOL_REGISTRY,
    )

    estimation = result.get("estimation", result)

    logger.info("Budget estimation complete", {"estimation": estimation})

    return {
        "budget_estimation": estimation,
        "events": [
            {
                "event": "budget",
                "data": {"estimation": estimation, "source": "amadeus+llm"},
            },
        ],
    }
