"""Persist a streamed AI plan as a ``DRAFT`` Trip + children.

SMP-324 — pre-refactor the wizard rebuilt the whole plan client-side
and POST'd it back to ``/v1/ai/plan-trip/accept`` for persistence.
That round-trip dropped fields silently (``estimated_cost``,
``suggested_day``, FOOD/TRANSPORT recommendations entirely) because
the Flutter view-model squashed the typed SSE payload into parallel
lists of strings. The backend already had the canonical data in
``TripPlanState`` at the end of the LangGraph pipeline; routing it
through the client was both unsafe and architecturally wrong.

The new flow:

1. The graph finishes; ``TripPlannerService.stream_plan`` calls
   :meth:`PlanDraftService.create_draft_from_state` directly.
2. A ``Trip`` is created with ``status=DRAFT``, plus every related row
   (Activity / Accommodation / ManualFlight / BaggageItem / BudgetItem)
   marked ``validation_status=SUGGESTED``.
3. The SSE ``complete`` event ships ``tripId`` so the wizard can load
   the trip via the standard ``GET /v1/trips/{id}`` and let the user
   review or discard.
4. Confirming the trip is just ``PATCH /v1/trips/{id}/status`` →
   ``PLANNED`` (existing endpoint, validates required fields).
   Discarding is ``DELETE /v1/trips/{id}``.
5. ``TRIP_STATUS_JOB`` collects DRAFT trips older than 24h so users
   who quit mid-review don't pollute the database.
"""

from __future__ import annotations

import contextlib
from datetime import UTC, date, datetime, time, timedelta
from typing import Any

from sqlalchemy.orm import Session

from src.enums import BudgetCategory, FlightType, ValidationStatus
from src.integrations.aviation_data.service import AviationDataService
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.models.trip import Trip
from src.models.user import User
from src.services.trips_service import TripsService
from src.utils.logger import logger

# ── Constants ─────────────────────────────────────────────────────────

TIME_OF_DAY_MAP: dict[str, time] = {
    "morning": time(9, 0),
    "afternoon": time(14, 0),
    "evening": time(19, 0),
}

_DEFAULT_BAGGAGE_I18N: dict[str, list[dict[str, Any]]] = {
    "en": [
        {"name": "Passport", "category": "DOCUMENTS", "quantity": 1},
        {"name": "Travel adapter", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Sunscreen", "category": "TOILETRIES", "quantity": 1},
        {"name": "First aid kit", "category": "HEALTH", "quantity": 1},
        {"name": "Phone charger", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Change of clothes", "category": "CLOTHING", "quantity": 3},
    ],
    "fr": [
        {"name": "Passeport", "category": "DOCUMENTS", "quantity": 1},
        {"name": "Adaptateur de voyage", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Creme solaire", "category": "TOILETRIES", "quantity": 1},
        {"name": "Trousse de premiers secours", "category": "HEALTH", "quantity": 1},
        {"name": "Chargeur de telephone", "category": "ELECTRONICS", "quantity": 1},
        {"name": "Vetements de rechange", "category": "CLOTHING", "quantity": 3},
    ],
}


def get_default_baggage(lang: str) -> list[dict[str, Any]]:
    """Fallback baggage list when the agent did not surface one."""
    return _DEFAULT_BAGGAGE_I18N.get(lang, _DEFAULT_BAGGAGE_I18N["en"])


# ── Pure helpers ──────────────────────────────────────────────────────


def parse_iso_datetime(value: object) -> datetime | None:
    """Best-effort parse of an ISO 8601 datetime. Returns None on failure."""
    if not value or not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def compute_nights(start: date | None, end: date | None) -> int:
    """Number of nights between two trip dates, 0 when either side is missing."""
    if start is None or end is None:
        return 0
    delta = (end - start).days
    return max(delta, 0)


def combine_date_to_utc_datetime(value: date | None) -> datetime | None:
    """Combine a trip date with midnight UTC for the
    ``DateTime(timezone=True)`` columns on Accommodation."""
    if value is None:
        return None
    return datetime.combine(value, time.min, tzinfo=UTC)


def _coerce_amount(raw: object) -> float:
    """Pull a numeric amount out of either a flat number or ``{amount: x}``."""
    value: object = raw.get("amount", 0) if isinstance(raw, dict) else raw
    if value is None or isinstance(value, bool):
        return 0.0
    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return 0.0


def _is_dated_activity(activity: dict) -> bool:
    """An itinerary entry is dated when the LLM pinned it to a slot.

    Undated rows (FOOD / TRANSPORT recommendations) live in dedicated
    review-screen sections and trip-detail tabs.
    """
    return activity.get("suggested_day") not in (None, "") or activity.get("time_of_day") not in (
        None,
        "",
    )


def _budget_category_for_activity(activity_category: str) -> BudgetCategory:
    """Map an Activity.category string onto the matching BudgetCategory."""
    upper = (activity_category or "").upper()
    if upper == BudgetCategory.FOOD.value:
        return BudgetCategory.FOOD
    if upper == BudgetCategory.TRANSPORT.value:
        return BudgetCategory.TRANSPORT
    return BudgetCategory.ACTIVITY


def _accommodation_stay_total(acc: dict, trip_nights: int) -> float:
    """Whole-stay accommodation cost — same precedence as ``budget_node``.

    Prefers ``price_total`` (Amadeus stay total). Falls back to
    ``price_per_night × nights``. Returns 0 when neither is usable so
    the caller skips creating an orphan BudgetItem.
    """
    price_total = acc.get("price_total")
    if isinstance(price_total, (int, float)) and price_total > 0:
        return float(price_total)
    price_per_night = acc.get("price_per_night")
    if isinstance(price_per_night, (int, float)) and price_per_night > 0 and trip_nights > 0:
        return float(price_per_night) * trip_nights
    return 0.0


def _build_budget_item(
    *,
    trip_id,
    label: str,
    amount: float,
    category: str,
    source_type: str | None = None,
    source_id=None,
    item_date: date | None = None,
) -> BudgetItem:
    """Factory for forecast budget lines created at draft persistence time."""
    return BudgetItem(
        trip_id=trip_id,
        label=label,
        amount=amount,
        category=category,
        date=item_date,
        is_planned=True,
        source_type=source_type,
        source_id=source_id,
    )


def _flight_offer_to_manual(
    *,
    trip_id,
    offer: dict,
    flight_type: str,
    fallback_dep: str | None,
    fallback_arr: str | None,
) -> ManualFlight:
    """Convert one Amadeus / synthetic offer dict into a ManualFlight row.

    The offer shape is the one produced by ``search_real_flights`` /
    ``_synthesize_flight_offer`` (``departure`` / ``arrival`` keys),
    which differs from the legacy "accept payload" shape
    (``departure_date`` / ``arrival_date``). This mapper bridges the two.
    """
    is_return = flight_type == FlightType.RETURN
    departure_iso = offer.get("return_departure" if is_return else "departure", "")
    arrival_iso = offer.get("return_arrival" if is_return else "arrival", "")
    duration = offer.get("return_duration" if is_return else "duration", "")

    dep_airport = offer.get("destination_iata" if is_return else "origin_iata") or fallback_dep
    arr_airport = offer.get("origin_iata" if is_return else "destination_iata") or fallback_arr

    notes_bits = [f"AI suggestion ({offer.get('source', 'estimated')})"]
    if duration:
        notes_bits.append(f"duration={duration}")

    return ManualFlight(
        trip_id=trip_id,
        flight_number=offer.get("flight_number") or "TBD",
        airline=offer.get("airline"),
        departure_airport=dep_airport,
        arrival_airport=arr_airport,
        departure_date=parse_iso_datetime(departure_iso),
        arrival_date=parse_iso_datetime(arrival_iso),
        price=offer.get("price"),
        currency=offer.get("currency", "EUR"),
        notes=" · ".join(notes_bits),
        flight_type=flight_type,
        validation_status=ValidationStatus.SUGGESTED,
    )


# ── Service ───────────────────────────────────────────────────────────


class PlanDraftService:
    """Persist a finished LangGraph ``TripPlanState`` as a DRAFT Trip."""

    _aviation = AviationDataService()

    @classmethod
    async def create_draft_from_state(
        cls,
        *,
        db: Session,
        user: User,
        state: dict[str, Any],
        accept_language: str,
    ) -> Trip:
        """Create a DRAFT Trip + children from a finished LangGraph state.

        The graph guarantees:
          - ``selected_destination`` populated
          - ``departure_date`` / ``return_date`` set (even on flexible
            modes — see ``_build_initial_state``).

        Returns the persisted :class:`Trip` instance with ``status=DRAFT``;
        the caller is responsible for refreshing if it needs computed fields.
        """
        dest_info = state.get("selected_destination") or {}
        dest_city = dest_info.get("city", "")
        dest_country = dest_info.get("country", "")
        destination_name = (
            f"{dest_city}, {dest_country}" if dest_country else dest_city or "Inconnu"
        )
        destination_iata = dest_info.get("iata") or cls._resolve_iata(dest_city)

        origin_iata = state.get("origin_iata") or cls._resolve_iata(state.get("origin_city") or "")

        cover_image_url = await cls._fetch_cover_image(destination_name)

        start_value, end_value = cls._normalize_dates(state)

        budget_target = state.get("target_budget")
        if not budget_target:
            estimation = state.get("budget_estimation") or {}
            band_max = estimation.get("total_max")
            if isinstance(band_max, (int, float)) and band_max > 0:
                budget_target = float(band_max)

        trip = TripsService.create_trip(
            db=db,
            user_id=user.id,
            title=f"Voyage à {destination_name}",
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            destination_name=destination_name,
            description=cls._compose_description(state),
            budget_target=budget_target,
            start_date=start_value,
            end_date=end_value,
            origin="AI",
            cover_image_url=cover_image_url,
            date_mode=(state.get("date_mode") or "EXACT").upper(),
            nb_travelers=state.get("nb_travelers"),
        )

        cls._persist_activities(db, trip, state, start_value)
        cls._persist_accommodations(db, trip, state)
        cls._persist_flights(db, trip, state)
        cls._persist_baggage(db, trip, state, accept_language)

        db.commit()
        db.refresh(trip)
        logger.info(
            "Draft trip persisted",
            {"trip_id": str(trip.id), "user_id": str(user.id), "status": trip.status},
        )
        return trip

    # ── Helpers ──────────────────────────────────────────────────────

    @classmethod
    def _resolve_iata(cls, city_name: str) -> str | None:
        if not city_name or not city_name.strip():
            return None
        try:
            results = cls._aviation.search_by_keyword(
                city_name.strip(), sub_type="CITY,AIRPORT", limit=1
            )
            if results:
                loc = results[0]
                return loc.iataCode or (loc.address.cityCode if loc.address else None)
        except Exception:
            logger.warn("Offline IATA resolution failed", {"city": city_name})
        return None

    @staticmethod
    async def _fetch_cover_image(destination_name: str) -> str:
        """Unsplash cover with a static continent fallback."""
        from src.integrations.unsplash import unsplash_client

        cover = await unsplash_client.fetch_cover_image(destination_name)
        return cover or unsplash_client.get_fallback_url(destination_name)

    @staticmethod
    def _normalize_dates(state: dict) -> tuple[str, str]:
        """Safety net: derive start/end dates if the wizard was on a
        flexible mode and somehow reached this stage without them."""
        start_value = state.get("departure_date") or ""
        end_value = state.get("return_date") or ""
        if start_value and end_value:
            return start_value, end_value
        duration = int(state.get("duration_days") or 7) or 7
        if not start_value:
            start_value = str(date.today() + timedelta(days=30))
        if not end_value:
            try:
                start = date.fromisoformat(start_value)
            except ValueError:
                start = date.today() + timedelta(days=30)
            end_value = str(start + timedelta(days=duration))
        return start_value, end_value

    @staticmethod
    def _compose_description(state: dict) -> str:
        dest_info = state.get("selected_destination") or {}
        city = dest_info.get("city", "destination")
        return f"AI-planned trip to {city}"

    # ── Persistence sub-methods (one per domain) ─────────────────────

    @staticmethod
    def _persist_activities(db: Session, trip: Trip, state: dict, start_value: str) -> None:
        activities_data = state.get("activities") or []
        if not activities_data:
            return

        trip_start: date | None = None
        if start_value:
            with contextlib.suppress(ValueError):
                trip_start = date.fromisoformat(start_value)

        dated_activities = [act for act in activities_data if _is_dated_activity(act)]
        duration_days = int(state.get("duration_days") or len(dated_activities) or 1)

        dated_index = 0
        for act in activities_data:
            activity_date: date | None = None
            start_time_value: time | None = None

            if _is_dated_activity(act):
                suggested_day = act.get("suggested_day")
                if isinstance(suggested_day, int) and suggested_day > 0:
                    day_offset = (suggested_day - 1) % max(duration_days, 1)
                else:
                    day_offset = dated_index % max(duration_days, 1)
                dated_index += 1

                activity_date = (
                    trip_start + timedelta(days=day_offset)
                    if trip_start
                    else date.today() + timedelta(days=day_offset)
                )
                start_time_value = TIME_OF_DAY_MAP.get(act.get("time_of_day", ""))

            cost = _coerce_amount(act.get("estimated_cost"))
            activity = Activity(
                trip_id=trip.id,
                title=act.get("title", "Activité"),
                description=act.get("description", ""),
                date=activity_date,
                start_time=start_time_value,
                location=act.get("location"),
                category=act.get("category", "OTHER"),
                estimated_cost=cost or None,
                validation_status=ValidationStatus.SUGGESTED,
            )
            db.add(activity)
            db.flush()

            if cost > 0:
                db.add(
                    _build_budget_item(
                        trip_id=trip.id,
                        label=activity.title,
                        amount=cost,
                        category=_budget_category_for_activity(act.get("category", "OTHER")),
                        source_type="activity",
                        source_id=activity.id,
                        item_date=activity_date,
                    )
                )

    @staticmethod
    def _persist_accommodations(db: Session, trip: Trip, state: dict) -> None:
        accommodations_data = state.get("accommodations") or []
        trip_nights = compute_nights(trip.start_date, trip.end_date)
        for acc in accommodations_data:
            accommodation = Accommodation(
                trip_id=trip.id,
                name=acc.get("name", "Hébergement"),
                address=acc.get("address"),
                check_in=combine_date_to_utc_datetime(trip.start_date),
                check_out=combine_date_to_utc_datetime(trip.end_date),
                price_per_night=acc.get("price_per_night"),
                currency=acc.get("currency", "EUR"),
                notes=acc.get("notes"),
                validation_status=ValidationStatus.SUGGESTED,
            )
            db.add(accommodation)
            db.flush()

            stay_total = _accommodation_stay_total(acc, trip_nights)
            if stay_total > 0:
                db.add(
                    _build_budget_item(
                        trip_id=trip.id,
                        label=accommodation.name,
                        amount=stay_total,
                        category=BudgetCategory.ACCOMMODATION,
                        source_type="accommodation",
                        source_id=accommodation.id,
                    )
                )

    @staticmethod
    def _persist_flights(db: Session, trip: Trip, state: dict) -> None:
        offers = state.get("flight_offers") or []
        if not offers:
            return
        offer = offers[0]

        outbound = _flight_offer_to_manual(
            trip_id=trip.id,
            offer=offer,
            flight_type=FlightType.MAIN,
            fallback_dep=trip.origin_iata,
            fallback_arr=trip.destination_iata,
        )
        db.add(outbound)
        db.flush()
        _maybe_add_flight_budget(db, trip.id, outbound, offer)

        # Round-trip: same offer carries the return leg fields when present.
        if offer.get("return_departure") or offer.get("return_arrival"):
            return_flight = _flight_offer_to_manual(
                trip_id=trip.id,
                offer=offer,
                flight_type=FlightType.RETURN,
                fallback_dep=trip.destination_iata,
                fallback_arr=trip.origin_iata,
            )
            db.add(return_flight)
            db.flush()
            _maybe_add_flight_budget(db, trip.id, return_flight, offer, leg="return")

    @staticmethod
    def _persist_baggage(db: Session, trip: Trip, state: dict, accept_language: str) -> None:
        ai_baggage = state.get("baggage_items") or []
        if not ai_baggage:
            lang = (accept_language or "fr")[:2]
            ai_baggage = get_default_baggage(lang)
        for bag in ai_baggage:
            db.add(
                BaggageItem(
                    trip_id=trip.id,
                    name=bag.get("name", "Item"),
                    quantity=bag.get("quantity", 1),
                    category=bag.get("category", "OTHER"),
                )
            )


def _maybe_add_flight_budget(
    db: Session,
    trip_id,
    flight: ManualFlight,
    offer: dict,
    *,
    leg: str = "outbound",
) -> None:
    """Add a FLIGHT BudgetItem when the offer ships a price.

    Round-trip offers carry a single ``price`` (the whole-trip total), so
    we only add the budget line for the outbound leg to avoid double-counting.
    """
    if leg == "return":
        return
    price = offer.get("price")
    if not price:
        return
    label = (
        f"{flight.flight_type.title()} flight "
        f"{flight.departure_airport or '?'}→{flight.arrival_airport or '?'}"
    )
    db.add(
        _build_budget_item(
            trip_id=trip_id,
            label=label,
            amount=float(price),
            category=BudgetCategory.FLIGHT,
            source_type="manual_flight",
            source_id=flight.id,
        )
    )
