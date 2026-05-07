"""Budget estimator node — deterministic aggregation over Amadeus + activities.

Every line in the breakdown must be backed by a review-able item:

  - Flight: ``Σ flight_offers.price`` (Amadeus, or haversine-derived
    placeholder when Amadeus is unavailable). The user reviews the
    flight card in trip detail.
  - Accommodation: best gathered hotel's stay total. Falls back to
    ``deferred`` (= 0) when no Amadeus hit so the review screen shows
    "Hôtel à choisir" without a fake price.
  - Activity / Food / Transport: ``Σ activities.estimated_cost``
    partitioned by ``Activity.category``. Each entry is a single
    activity row the user can edit or delete in trip detail, so the
    breakdown line is always traceable to a concrete item.

What this node *does not* do anymore: a per-diem table that fabricated
a flat 45 €/day food and 18 €/day transport line, regardless of the
actual restaurants / transit items the agent surfaced. Those lines
were unreviewable (no item to attach the spending to) and divergent
between the review screen and trip detail. SMP-324 removed them; the
review now shows only what the user can later validate item-by-item.
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


def _flight_total_from_offers(offers: list[dict]) -> float:
    """Sum the per-traveler price field of every offer (Amadeus or synthetic)."""
    total = 0.0
    for offer in offers:
        try:
            total += float(offer.get("price", 0) or 0)
        except (TypeError, ValueError):
            continue
    return total


_FOOD_CATEGORY = "FOOD"
_TRANSPORT_CATEGORY = "TRANSPORT"


def _partition_activity_costs(activities: list[dict]) -> tuple[float, float, float]:
    """Sum ``estimated_cost`` per category bucket.

    Returns ``(food_total, transport_total, other_activity_total)`` so
    the breakdown line for each category equals the sum of the items
    the user will see (and can edit) in the trip-detail tabs. Anything
    that isn't FOOD/TRANSPORT lands in the generic activity bucket
    (CULTURE, NATURE, SPORT, SHOPPING, NIGHTLIFE, RELAXATION, OTHER).
    """
    food_total = 0.0
    transport_total = 0.0
    other_total = 0.0
    for activity in activities:
        try:
            cost = float(activity.get("estimated_cost", 0) or 0)
        except (TypeError, ValueError):
            continue
        if cost <= 0:
            continue
        category = (activity.get("category") or "").upper()
        if category == _FOOD_CATEGORY:
            food_total += cost
        elif category == _TRANSPORT_CATEGORY:
            transport_total += cost
        else:
            other_total += cost
    return food_total, transport_total, other_total


def _build_estimation(
    *,
    flight_total: float,
    accommodation_total: float,
    food_total: float,
    transport_total: float,
    activity_total: float,
    flight_source: str,
    accommodation_source: str,
) -> dict:
    """Assemble the singular-key estimation payload the front consumes.

    Every line maps 1:1 onto a ``BudgetItem`` the persistence layer
    creates at ``/plan-trip/accept``: the flight offer, the hotel stay,
    and one item per costed Activity (FOOD / TRANSPORT / other). The
    review screen and trip detail therefore agree by construction —
    Σ phase 1 == Σ phase 2 the moment the user accepts.
    """
    total = flight_total + accommodation_total + food_total + transport_total + activity_total
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
            "amount": round(food_total, 2),
            "currency": "EUR",
            "source": "gathered_data" if food_total > 0 else "estimated",
        },
        "transport": {
            "amount": round(transport_total, 2),
            "currency": "EUR",
            "source": "gathered_data" if transport_total > 0 else "estimated",
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
    """Aggregate the budget deterministically from Amadeus + activities."""
    guard(state, min_required=2.0)
    logger.info("=== Budget Estimator Node ===")

    dest = state.get("selected_destination", {})
    accommodations = state.get("accommodations", []) or []
    activities = state.get("activities", []) or []
    origin_iata = state.get("origin_iata", "") or ""
    dest_iata = dest.get("iata", "") or ""
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

    # ── Accommodation: prefer the gathered Amadeus stay total. If the
    # accommodation node returned a ``deferred`` marker (no Amadeus hit
    # → the review card shows "Hôtel à choisir" without a price), keep
    # this budget line at 0 with ``source="deferred"`` so the breakdown
    # stays consistent with the card. The total_min/max therefore
    # exclude accommodation in that case — the user knows they still
    # need to add a hotel before reading the bottom line.
    accom_total = 0.0
    accom_source = "deferred" if accommodations else "estimated"
    if accommodations:
        gathered_total = _accommodation_stay_total(accommodations[0])
        if gathered_total > 0:
            accom_total = gathered_total
            accom_source = "amadeus"

    # ── Activities: partition by category so each breakdown line maps
    # 1:1 onto the BudgetItems the acceptance flow will persist.
    food_total, transport_total, other_activity_total = _partition_activity_costs(activities)

    estimation = _build_estimation(
        flight_total=flight_total,
        accommodation_total=accom_total,
        food_total=food_total,
        transport_total=transport_total,
        activity_total=other_activity_total,
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
