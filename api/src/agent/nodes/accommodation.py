"""Accommodation node — searches real hotels via Amadeus."""

from __future__ import annotations

from src.agent.prompts import ACCOMMODATION_PROMPT
from src.agent.react_executor import react_execute
from src.agent.state import TripPlanState
from src.agent.tools import TOOL_REGISTRY
from src.utils.logger import logger


async def accommodation_node(state: TripPlanState) -> dict:
    """Search real hotel prices using Amadeus via ReAct tools."""
    logger.info("=== Accommodation Node ===")

    dest = state.get("selected_destination", {})
    iata = dest.get("iata", "")
    city = dest.get("city", "Unknown")
    country = dest.get("country", "")

    parts = [
        f"Destination: {city}, {country} (IATA: {iata})",
    ]
    if state.get("departure_date"):
        parts.append(f"Check-in: {state['departure_date']}")
    if state.get("return_date"):
        parts.append(f"Check-out: {state['return_date']}")
    if state.get("companions"):
        parts.append(f"Travelers: {state['companions']}")
    if state.get("budget_range"):
        parts.append(f"Budget: {state['budget_range']}")
    if state.get("budget_preset"):
        from src.api.ai.plan_trip_schemas import BUDGET_PRESET_RANGES

        label = BUDGET_PRESET_RANGES.get(state["budget_preset"], {}).get(
            "label", state["budget_preset"]
        )
        parts.append(f"Budget level: {label}")
    if state.get("nb_travelers"):
        parts.append(f"Number of travelers: {state['nb_travelers']}")

    user_prompt = "\n".join(parts)

    tool_names = ["search_real_hotels"]
    result = await react_execute(
        agent_instruction=ACCOMMODATION_PROMPT,
        user_prompt=user_prompt,
        tool_names=tool_names,
        tool_registry=TOOL_REGISTRY,
    )

    accommodations = result.get("accommodations", [])

    # If no real data, mark as estimated
    source = (
        "amadeus"
        if accommodations and any(a.get("source") == "amadeus" for a in accommodations)
        else "estimated"
    )

    logger.info("Accommodation search complete", {"count": len(accommodations), "source": source})

    return {
        "accommodations": accommodations,
        "events": [
            {
                "event": "accommodations",
                "data": {"accommodations": accommodations, "source": source},
            },
        ],
    }
