"""Budget estimator node — uses real flight prices + gathered hotel/activity data."""

from __future__ import annotations

import json

from src.agent.budget import guard
from src.agent.prompts import render
from src.agent.react_executor import react_execute
from src.agent.state import TripPlanState
from src.agent.tools import TOOL_REGISTRY
from src.utils.logger import logger

_BUDGET_KEYS = ["flights", "accommodation", "meals", "transport", "activities"]


def _extract_amount(value) -> float:
    """Extract a numeric amount from a budget category value."""
    if isinstance(value, dict):
        amt = value.get("amount", 0)
        return float(amt) if isinstance(amt, (int, float)) else 0.0
    if isinstance(value, (int, float)):
        return float(value)
    return 0.0


def _sum_estimation(estimation: dict) -> float:
    """Sum all breakdown category amounts in an estimation dict."""
    return sum(_extract_amount(estimation.get(k)) for k in _BUDGET_KEYS)


def _compute_fallback_budget(accommodations: list, activities: list, estimation: dict) -> dict:
    """Compute budget from real gathered data when LLM estimation is incomplete."""
    # Best accommodation price
    accom_total = 0.0
    if accommodations:
        best = accommodations[0]
        accom_total = float(best.get("price_total") or best.get("price_per_night", 0) or 0)

    # Sum activity costs
    activity_total = sum(float(a.get("estimated_cost", 0) or 0) for a in activities)

    # Preserve valid LLM data for flights / meals / transport
    def _keep_or_default(key: str) -> tuple[dict, float]:
        raw = estimation.get(key, {})
        amt = _extract_amount(raw)
        if isinstance(raw, dict) and amt > 0:
            return raw, amt
        return {"amount": amt, "currency": "EUR", "source": "estimated"}, amt

    flights_data, flight_amt = _keep_or_default("flights")
    meals_data, meals_amt = _keep_or_default("meals")
    transport_data, transport_amt = _keep_or_default("transport")

    total = flight_amt + accom_total + activity_total + meals_amt + transport_amt

    return {
        "flights": flights_data,
        "accommodation": {"amount": accom_total, "currency": "EUR", "source": "gathered_data"},
        "meals": meals_data,
        "transport": transport_data,
        "activities": {"amount": activity_total, "currency": "EUR", "source": "gathered_data"},
        "total_min": int(total * 0.85),
        "total_max": int(total * 1.15),
        "currency": "EUR",
    }


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

    # Direct flight search to capture raw offer data for Flutter display
    from src.agent.tools import search_real_flights

    flight_offers: list[dict] = []
    origin_iata = state.get("origin_iata", "")
    dest_iata = dest.get("iata", "")
    if origin_iata and dest_iata and state.get("departure_date"):
        try:
            flight_result = await search_real_flights(
                origin=origin_iata,
                destination=dest_iata,
                date=state["departure_date"],
                return_date=state.get("return_date"),
                adults=state.get("nb_travelers", 1),
            )
            flight_offers = flight_result.get("flights", [])
        except Exception as e:
            logger.warn("Direct flight search for raw data failed", {"error": str(e)})

    # ReAct with flight search tool
    tool_names = ["search_real_flights", "resolve_iata_code"]
    result = await react_execute(
        agent_instruction=render("budget", locale=state.get("locale", "en")),
        user_prompt=user_prompt,
        tool_names=tool_names,
        tool_registry=TOOL_REGISTRY,
    )

    estimation = result.get("estimation", result)

    # Validate: if breakdown sums to 0, compute fallback from gathered data
    llm_total = _sum_estimation(estimation)
    if llm_total == 0:
        llm_total = max(
            float(estimation.get("total_max", 0) or 0),
            float(estimation.get("total_min", 0) or 0),
        )
    if llm_total == 0 and (accommodations or activities):
        logger.warn(
            "Budget LLM returned zero estimation, computing fallback from gathered data",
            {"raw_estimation": estimation},
        )
        estimation = _compute_fallback_budget(accommodations, activities, estimation)

    logger.info("Budget estimation complete", {"estimation": estimation})

    return {
        "budget_estimation": estimation,
        "flight_offers": flight_offers,
        "events": [
            {
                "event": "budget",
                "data": {"estimation": estimation, "source": "amadeus+llm"},
            },
        ],
    }
