"""Budget estimator node — uses real flight prices + gathered hotel/activity data."""

from __future__ import annotations

import json
from datetime import datetime, time, timedelta

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


def _synthesize_flight_offer(
    *,
    origin_iata: str,
    dest_iata: str,
    departure_date: str,
    return_date: str | None,
    flight_price: float,
    currency: str = "EUR",
) -> list[dict]:
    """Build a deterministic flight-offer payload when Amadeus is unavailable.

    The plan must still show *something* to the user — otherwise the Flutter
    review drops the whole flight card (bug reported on SMP-316 for
    Barcelone). Rather than asking the LLM to fabricate airline codes
    (which causes hallucinations and makes the `source` field unreliable),
    we fill the slot with plausible placeholder hours and mark every field
    as ``source="estimated"``. The user validates or edits later via
    trip_detail.

    Heuristics:
    - Outbound: 10:00 → 12:00 local of `departure_date` (2h default)
    - Return:   18:00 → 20:00 local of `return_date`
    - Flight number empty → client renders em-dash
    - Airline: "Estimated" so the UI shows the estimated source badge
    """
    try:
        dep_day = datetime.fromisoformat(departure_date)
    except ValueError:
        return []

    dep_dt = datetime.combine(dep_day.date(), time(10, 0))
    arr_dt = dep_dt + timedelta(hours=2)
    offer: dict = {
        "airline": "EST",
        "airline_name": "Estimated",
        "flight_number": "",
        "price": flight_price,
        "currency": currency,
        "departure": dep_dt.isoformat(),
        "arrival": arr_dt.isoformat(),
        "duration": "PT2H",
        "origin_iata": origin_iata,
        "destination_iata": dest_iata,
        "source": "estimated",
    }
    if return_date:
        try:
            ret_day = datetime.fromisoformat(return_date)
        except ValueError:
            return [offer]
        ret_dt = datetime.combine(ret_day.date(), time(18, 0))
        ret_arr = ret_dt + timedelta(hours=2)
        offer["return_departure"] = ret_dt.isoformat()
        offer["return_arrival"] = ret_arr.isoformat()
        offer["return_duration"] = "PT2H"
    return [offer]


def _accommodation_stay_total(best: dict) -> float:
    """Return the whole-stay accommodation cost from a hotel dict.

    Prefers the explicit ``price_total`` (Amadeus stay total). Falls back
    to ``price_per_night × nights`` when only the per-night unit is known
    (LLM-only path, missing tool data). Returns 0 if neither is exploitable.
    Resolves B23: callers used to read ``price_total or price_per_night``
    and the per-night branch silently fed an under-counted budget.
    """
    price_total = best.get("price_total")
    if isinstance(price_total, (int, float)) and price_total > 0:
        return float(price_total)
    per_night = best.get("price_per_night")
    nights = best.get("nights")
    if (
        isinstance(per_night, (int, float))
        and per_night > 0
        and isinstance(nights, (int, float))
        and nights > 0
    ):
        return float(per_night) * float(nights)
    return 0.0


def _compute_fallback_budget(accommodations: list, activities: list, estimation: dict) -> dict:
    """Compute budget from real gathered data when LLM estimation is incomplete."""
    # Best accommodation total — see _accommodation_stay_total for unit rules.
    accom_total = _accommodation_stay_total(accommodations[0]) if accommodations else 0.0

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

    # Remember whether Amadeus actually produced anything — we might need to
    # synthesize a fallback offer after the LLM returns a budget estimation.
    _amadeus_delivered = len(flight_offers) > 0

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

    # Synthesize a placeholder flight offer when Amadeus returned nothing.
    # Keeps the review + trip_detail flight cards populated instead of a
    # silent drop (bug SMP-316 on Barcelone).
    if not _amadeus_delivered and origin_iata and dest_iata and state.get("departure_date"):
        flight_price = _extract_amount(estimation.get("flights"))
        synthetic = _synthesize_flight_offer(
            origin_iata=origin_iata,
            dest_iata=dest_iata,
            departure_date=state["departure_date"],
            return_date=state.get("return_date"),
            flight_price=flight_price,
        )
        if synthetic:
            logger.info(
                "Amadeus unavailable, emitting estimated flight offer",
                {"origin": origin_iata, "destination": dest_iata},
            )
            flight_offers = synthetic

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
