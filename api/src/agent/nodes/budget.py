"""Budget estimator node — deterministic aggregation over Amadeus + per-diem table.

Pre-SMP-324 this node ran a ReAct loop over ``search_real_flights`` and
``resolve_iata_code``, asking the LLM to fold five categories
(flight / accommodation / food / transport / activity) into one JSON
estimation. That worked when every input was perfect but stalled hard
the moment a localized destination_city left ``destination_iata`` empty:
the LLM emitted "Thought: Need IATA code for Singapore." with no Action,
the JSON parse failed, and the budget came back as 0 EUR — exactly the
production stall this PR was filed to remove.

The new implementation is deterministic:

  - Flight: read directly from the offers Amadeus already returned in
    the same node (or from the synthesized placeholder when Amadeus
    is unavailable).
  - Accommodation: sum of the best gathered hotel's stay total,
    using the existing ``_accommodation_stay_total`` helper.
  - Activity: sum of activities' ``estimated_cost``.
  - Food + transport: per-diem table (per traveler / per day), tuned
    to the ``budget_preset`` band selected by the wizard.

The LLM is no longer in the critical path of the budget. We keep the
SSE event format identical so the front-end and the persistence layer
don't move.
"""

from __future__ import annotations

from datetime import datetime, time, timedelta

from src.agent.runtime_budget import guard
from src.agent.state import TripPlanState
from src.utils.logger import logger

# Topic 05 (B12) — singular keys aligned with the Flutter `BudgetCategory`
# enum (FLIGHT/ACCOMMODATION/FOOD/ACTIVITY/TRANSPORT). The legacy plural
# variants (flights/meals/activities) are gone — no implicit mapping.
_BUDGET_KEYS = ["flight", "accommodation", "food", "transport", "activity"]


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

    flight_data, flight_amt = _keep_or_default("flight")
    food_data, food_amt = _keep_or_default("food")
    transport_data, transport_amt = _keep_or_default("transport")

    total = flight_amt + accom_total + activity_total + food_amt + transport_amt

    return {
        "flight": flight_data,
        "accommodation": {"amount": accom_total, "currency": "EUR", "source": "gathered_data"},
        "food": food_data,
        "transport": transport_data,
        "activity": {"amount": activity_total, "currency": "EUR", "source": "gathered_data"},
        "total_min": int(total * 0.85),
        "total_max": int(total * 1.15),
        "currency": "EUR",
    }


# Per-traveler / per-day daily costs in EUR. Coarse on purpose — better
# to be 20 % off than to ask the LLM and stall on a "Thought:" parse error.
# Tuned roughly against eurostat & numbeo medians, biased to err on the
# safe (slightly high) side for the user's expectations.
_PER_DIEM_TABLE: dict[str, dict[str, float]] = {
    "low": {"food": 25.0, "transport": 10.0},
    "mid": {"food": 45.0, "transport": 18.0},
    "premium": {"food": 90.0, "transport": 35.0},
}
_DEFAULT_PER_DIEM = _PER_DIEM_TABLE["mid"]


def _flight_total_from_offers(offers: list[dict]) -> float:
    """Sum the per-traveler price field of every offer (Amadeus or synthetic)."""
    total = 0.0
    for offer in offers:
        try:
            total += float(offer.get("price", 0) or 0)
        except (TypeError, ValueError):
            continue
    return total


def _per_diem_for(state: TripPlanState) -> dict[str, float]:
    preset = (state.get("budget_preset") or "").lower()
    return _PER_DIEM_TABLE.get(preset, _DEFAULT_PER_DIEM)


def _build_estimation(
    *,
    flight_total: float,
    accommodation_total: float,
    activity_total: float,
    duration_days: int,
    nb_travelers: int,
    per_diem: dict[str, float],
    flight_source: str,
    accommodation_source: str,
) -> dict:
    """Assemble the singular-key estimation payload the front consumes."""
    food_total = round(per_diem["food"] * duration_days * nb_travelers, 2)
    transport_total = round(per_diem["transport"] * duration_days * nb_travelers, 2)

    total = flight_total + accommodation_total + activity_total + food_total + transport_total
    return {
        "flight": {
            "amount": round(flight_total, 2),
            "currency": "EUR",
            "source": flight_source,
        },
        "accommodation": {
            "amount": round(accommodation_total, 2),
            "currency": "EUR",
            "source": accommodation_source,
        },
        "food": {
            "amount": food_total,
            "currency": "EUR",
            "source": "per_diem",
            "per_day_per_person": per_diem["food"],
        },
        "transport": {
            "amount": transport_total,
            "currency": "EUR",
            "source": "per_diem",
            "per_day_per_person": per_diem["transport"],
        },
        "activity": {
            "amount": round(activity_total, 2),
            "currency": "EUR",
            "source": "gathered_data" if activity_total > 0 else "estimated",
        },
        "total_min": int(total * 0.85),
        "total_max": int(total * 1.15),
        "currency": "EUR",
    }


async def budget_node(state: TripPlanState) -> dict:
    """Aggregate the budget deterministically from Amadeus + per-diem table."""
    guard(state, min_required=2.0)
    logger.info("=== Budget Estimator Node ===")

    dest = state.get("selected_destination", {})
    accommodations = state.get("accommodations", []) or []
    activities = state.get("activities", []) or []
    origin_iata = state.get("origin_iata", "") or ""
    dest_iata = dest.get("iata", "") or ""
    duration_days = int(state.get("duration_days") or 1) or 1
    nb_travelers = int(state.get("nb_travelers") or 1) or 1

    # ── Flights: try Amadeus directly; synthesize a placeholder otherwise.
    flight_offers: list[dict] = []
    flight_source = "estimated"
    if origin_iata and dest_iata and state.get("departure_date"):
        from src.agent.tools import search_real_flights

        try:
            flight_result = await search_real_flights(
                origin=origin_iata,
                destination=dest_iata,
                date=state["departure_date"],
                return_date=state.get("return_date"),
                adults=nb_travelers,
            )
            flight_offers = flight_result.get("flights", []) or []
            if flight_offers:
                flight_source = "amadeus"
        except Exception as exc:
            logger.warn("budget_node: direct flight search failed", {"error": str(exc)})

    if not flight_offers and origin_iata and dest_iata and state.get("departure_date"):
        # Synthesize a placeholder so the review screen still shows a flight
        # card — preserves the SMP-316 fix for Barcelone-style empty cards.
        per_offer_estimate = _per_diem_for(state)["food"] * duration_days  # rough heuristic
        flight_offers = _synthesize_flight_offer(
            origin_iata=origin_iata,
            dest_iata=dest_iata,
            departure_date=state["departure_date"],
            return_date=state.get("return_date"),
            flight_price=per_offer_estimate,
        )

    flight_total = _flight_total_from_offers(flight_offers)

    # ── Accommodation: best stay total (existing helper).
    accom_total = _accommodation_stay_total(accommodations[0]) if accommodations else 0.0
    accom_source = "amadeus" if accom_total > 0 else "estimated"

    # ── Activities: sum of gathered estimated costs.
    activity_total = sum(float(a.get("estimated_cost", 0) or 0) for a in activities)

    # ── Per-diem food + transport.
    per_diem = _per_diem_for(state)

    estimation = _build_estimation(
        flight_total=flight_total,
        accommodation_total=accom_total,
        activity_total=activity_total,
        duration_days=duration_days,
        nb_travelers=nb_travelers,
        per_diem=per_diem,
        flight_source=flight_source,
        accommodation_source=accom_source,
    )

    logger.info(
        "Budget estimation complete",
        {
            "flight": estimation["flight"]["amount"],
            "accommodation": estimation["accommodation"]["amount"],
            "food": estimation["food"]["amount"],
            "transport": estimation["transport"]["amount"],
            "activity": estimation["activity"]["amount"],
            "source_mix": {
                "flight": flight_source,
                "accommodation": accom_source,
            },
        },
    )

    return {
        "budget_estimation": estimation,
        "flight_offers": flight_offers,
        "events": [
            {
                "event": "budget",
                "data": {"estimation": estimation, "source": "deterministic"},
            },
        ],
    }
