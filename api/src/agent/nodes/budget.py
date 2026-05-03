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

import math
from datetime import datetime, time, timedelta

from src.agent.runtime_budget import guard
from src.agent.state import TripPlanState
from src.integrations.aviation_data import aviation_data_service
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


# Commercial-jet cruise speed used to translate distance into flight time.
# 800 km/h is the typical effective ground speed averaged across taxi,
# climb, cruise and descent; gets us within ~10% of real schedules.
_AVERAGE_FLIGHT_KMPH = 800.0
# Fixed per-passenger one-way overhead (taxes, airport fees, fuel surcharge).
_FLIGHT_FIXED_OVERHEAD_EUR = 80.0
# Per-km coefficient — empirical mid-range fare for economy round-trip,
# tuned against typical CDG outbound prices. Round-trip is computed as
# ``2 × one_way`` so a single coefficient parameterizes the whole curve.
_FLIGHT_PER_KM_EUR = 0.10


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance between two coords in kilometres."""
    radius_km = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius_km * c


def _airport_coords(iata: str) -> tuple[float, float] | None:
    """Look up an airport's coordinates via the offline aviation dataset."""
    if not iata:
        return None
    loc = aviation_data_service.get_by_id(iata)
    if loc is None:
        return None
    return float(loc.geoCode.latitude), float(loc.geoCode.longitude)


def _estimate_flight_duration_hours(distance_km: float) -> float:
    """Translate a great-circle distance into a plausible flight duration.

    Adds a 1-hour ground buffer (taxi, turn-around) on top of the cruise
    estimate so a Paris-Lyon hop doesn't look unrealistically short.
    """
    if distance_km <= 0:
        return 2.0
    return distance_km / _AVERAGE_FLIGHT_KMPH + 1.0


def _estimate_flight_price_eur(distance_km: float, *, adults: int, round_trip: bool) -> float:
    """Estimate a round-trip economy fare in EUR for the requested party.

    The function returns the *total* price for ``adults`` passengers so
    the call-site can drop it straight into the budget breakdown.
    Distance under-counted on short hops is dwarfed by the fixed
    overhead, distance over-counted on long-haul leaves enough headroom
    that the user never sees a 300 € Tokyo (the bug this fix targets).
    """
    one_way = _FLIGHT_FIXED_OVERHEAD_EUR + _FLIGHT_PER_KM_EUR * max(distance_km, 0)
    multiplier = 2.0 if round_trip else 1.0
    return round(one_way * multiplier * max(adults, 1), 2)


def _synthesize_flight_offer(
    *,
    origin_iata: str,
    dest_iata: str,
    departure_date: str,
    return_date: str | None,
    nb_travelers: int = 1,
    currency: str = "EUR",
) -> list[dict]:
    """Build a deterministic flight-offer payload when Amadeus is unavailable.

    The review screen needs to show *something* to the user — otherwise
    the Flutter card drops to "ALLER" with empty hours (bug SMP-316 for
    Barcelone, regression observed on Paris→Tokyo when the Amadeus
    sandbox returned 500). Rather than asking the LLM to fabricate
    airline codes (which makes the ``source`` field unreliable), we
    derive duration and price from the great-circle distance between
    the two airports and stamp the result with ``source="estimated"``
    so the UI can render the estimated badge. The user validates or
    edits later via trip_detail.

    Heuristics:
        - Distance: haversine over ``aviation_data`` coords.
        - Duration: distance / 800 km/h + 1 h taxi/turn-around.
        - Price: ``2 × (80 + 0.10 × distance_km) × adults`` (round-trip).
        - Outbound starts at 10:00 local of ``departure_date``.
        - Return at 18:00 local of ``return_date``.
        - Flight number empty → the client renders em-dash.
        - Airline ``EST`` / "Estimated" so the badge stays consistent.
    """
    try:
        dep_day = datetime.fromisoformat(departure_date)
    except ValueError:
        return []

    origin_coords = _airport_coords(origin_iata)
    dest_coords = _airport_coords(dest_iata)
    if origin_coords and dest_coords:
        distance_km = _haversine_km(*origin_coords, *dest_coords)
    else:
        # Both IATAs missing from airportsdata is rare but possible
        # (private fields, older codes). Default to a short-haul shape so
        # the card still renders without lying about long-haul times.
        distance_km = 0.0
    duration_hours = _estimate_flight_duration_hours(distance_km)
    duration_seconds = int(round(duration_hours * 3600))
    iso_duration = _seconds_to_iso8601(duration_seconds)
    flight_price = _estimate_flight_price_eur(
        distance_km, adults=nb_travelers, round_trip=bool(return_date)
    )

    dep_dt = datetime.combine(dep_day.date(), time(10, 0))
    arr_dt = dep_dt + timedelta(seconds=duration_seconds)
    offer: dict = {
        "airline": "EST",
        "airline_name": "Estimated",
        "flight_number": "",
        "price": flight_price,
        "currency": currency,
        "departure": dep_dt.isoformat(),
        "arrival": arr_dt.isoformat(),
        "duration": iso_duration,
        "origin_iata": origin_iata,
        "destination_iata": dest_iata,
        "source": "estimated",
        "estimated_distance_km": int(distance_km),
    }
    if return_date:
        try:
            ret_day = datetime.fromisoformat(return_date)
        except ValueError:
            return [offer]
        ret_dt = datetime.combine(ret_day.date(), time(18, 0))
        ret_arr = ret_dt + timedelta(seconds=duration_seconds)
        offer["return_departure"] = ret_dt.isoformat()
        offer["return_arrival"] = ret_arr.isoformat()
        offer["return_duration"] = iso_duration
    return [offer]


def _seconds_to_iso8601(total_seconds: int) -> str:
    """Format a duration as ISO-8601 (e.g. ``PT13H10M``)."""
    if total_seconds <= 0:
        return "PT0M"
    hours, remainder = divmod(total_seconds, 3600)
    minutes = remainder // 60
    parts = ["PT"]
    if hours:
        parts.append(f"{hours}H")
    if minutes:
        parts.append(f"{minutes}M")
    if hours == 0 and minutes == 0:
        parts.append("0M")
    return "".join(parts)


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
    # ``accommodation`` is per-room / per-night and only kicks in when the
    # accommodation node returned a deferred placeholder (no Amadeus hit).
    # It feeds the budget breakdown but never the hotel card itself.
    "low": {"food": 25.0, "transport": 10.0, "accommodation": 60.0},
    "mid": {"food": 45.0, "transport": 18.0, "accommodation": 120.0},
    "premium": {"food": 90.0, "transport": 35.0, "accommodation": 280.0},
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
        # Duration and price are now derived from the great-circle distance
        # between the two IATAs (haversine over airportsdata coords) so a
        # Paris-Tokyo no longer renders as a 2-hour 315 € flight.
        flight_offers = _synthesize_flight_offer(
            origin_iata=origin_iata,
            dest_iata=dest_iata,
            departure_date=state["departure_date"],
            return_date=state.get("return_date"),
            nb_travelers=nb_travelers,
        )

    flight_total = _flight_total_from_offers(flight_offers)

    # ── Per-diem table (food, transport, accommodation fallback).
    per_diem = _per_diem_for(state)

    # ── Accommodation: prefer the gathered Amadeus stay total. When the
    # accommodation node returned a deferred placeholder (no Amadeus hit),
    # fall back to ``accommodation_per_diem × nights``. This keeps the
    # *budget* informed even though the *hotel card* stays empty — the
    # split is intentional: we never want to invent a hotel name.
    accom_total = _accommodation_stay_total(accommodations[0]) if accommodations else 0.0
    if accom_total > 0:
        accom_source = "amadeus"
    else:
        accom_total = round(per_diem["accommodation"] * duration_days, 2)
        accom_source = "per_diem"

    # ── Activities: sum of gathered estimated costs.
    activity_total = sum(float(a.get("estimated_cost", 0) or 0) for a in activities)

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
