"""Turn a streamed AI plan into a persisted Trip + children.

The HTTP handler for `POST /v1/ai/plan-trip/accept` used to carry ~250 lines
of inline ORM work (trip create + activities + accommodations + flights +
baggage + budget items + Unsplash cover fetch + IATA resolution). That
violated the CLAUDE.md rule that routes stay thin and left the flow
untestable without the full FastAPI stack.

`PlanAcceptanceService.create_trip_from_plan` is the single owner of that
flow now. The route becomes a pass-through that just wraps the result.
"""

from __future__ import annotations

import contextlib
import re
from datetime import UTC, date, datetime, time, timedelta
from typing import Any

from sqlalchemy.orm import Session

from src.api.ai.plan_trip_schemas import AcceptPlanRequest
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


# ── Pure helpers (stateless, unit-tested directly) ────────────────────


def parse_flight_route(route: str) -> tuple[str | None, str | None]:
    """Extract departure and arrival IATA codes from a route string.

    Handles formats like ``"CDG → JTR"``, ``"CDG -> JTR"``, ``"CDG - JTR"``.
    """
    codes = re.findall(r"\b([A-Z]{3})\b", route.upper())
    if len(codes) >= 2:
        return codes[0], codes[1]
    if len(codes) == 1:
        return codes[0], None
    return None, None


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


def _build_manual_flight(
    *,
    trip_id,
    flight_data: dict,
    flight_type: str,
    dep_airport: str | None,
    arr_airport: str | None,
) -> ManualFlight:
    """Build a ManualFlight row from a suggestion's flight dict.

    Marks the row as SUGGESTED so the client can distinguish LLM proposals
    from user-validated entries. Every column the LLM can surface is set.
    """
    price = flight_data.get("price")
    duration = flight_data.get("duration")
    notes_bits = [f"AI suggestion ({flight_data.get('source', 'estimated')})"]
    if duration:
        notes_bits.append(f"duration={duration}")
    details = flight_data.get("details")
    if details:
        notes_bits.append(str(details))
    return ManualFlight(
        trip_id=trip_id,
        flight_number=flight_data.get("flight_number") or "TBD",
        airline=flight_data.get("airline"),
        departure_airport=dep_airport,
        arrival_airport=arr_airport,
        departure_date=parse_iso_datetime(flight_data.get("departure_date")),
        arrival_date=parse_iso_datetime(flight_data.get("arrival_date")),
        price=price,
        currency=flight_data.get("currency", "EUR"),
        notes=" · ".join(notes_bits),
        flight_type=flight_type,
        validation_status=ValidationStatus.SUGGESTED,
    )


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
    """Factory for forecast budget lines created at plan acceptance time."""
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


def _coerce_breakdown_amount(raw: object) -> float:
    """Pull the numeric amount out of a breakdown entry.

    The SSE event ships each line as ``{"amount": float, "currency": str,
    "source": str}``; older code paths sometimes shipped the raw float.
    Accept both shapes and fall back to 0 on anything unparsable.
    """
    value: object = raw.get("amount", 0) if isinstance(raw, dict) else raw
    if value is None or isinstance(value, bool):
        return 0.0
    try:
        return float(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return 0.0


def _coerce_iso_date(value: str | date | None) -> date | None:
    """Convert a YYYY-MM-DD string (the resolver output) to a ``date``.

    ``BudgetItem.date`` is a SQLAlchemy ``Date`` column, so the persister
    must hand it a real ``datetime.date`` rather than the ISO string the
    rest of the service passes around.
    """
    if value is None or isinstance(value, date):
        return value
    try:
        return date.fromisoformat(value)
    except (TypeError, ValueError):
        return None


# ── Service ───────────────────────────────────────────────────────────


class PlanAcceptanceService:
    """Orchestrates the trip-creation flow from an accepted AI plan."""

    _aviation = AviationDataService()

    @classmethod
    async def create_trip_from_plan(
        cls,
        *,
        db: Session,
        user: User,
        request: AcceptPlanRequest,
        accept_language: str,
    ) -> dict:
        """Main entry point — creates Trip + children and returns a JSON dict.

        The return shape matches the legacy route response so the switch to the
        service is transparent to the Flutter client.
        """
        suggestion = request.suggestion
        destination_name, destination_iata = cls._resolve_destination(suggestion, request)
        origin_iata = cls._resolve_origin(suggestion, request)
        cover_image_url = await cls._fetch_cover_image(destination_name)
        start_date_value, end_date_value = cls._resolve_dates(request, suggestion)

        trip = TripsService.create_trip(
            db=db,
            user_id=user.id,
            title=f"Voyage à {destination_name}",
            origin_iata=origin_iata,
            destination_iata=destination_iata,
            destination_name=destination_name,
            description=suggestion.get("description"),
            budget_target=suggestion.get("budgetEur"),
            start_date=start_date_value,
            end_date=end_date_value,
            origin="AI",
            cover_image_url=cover_image_url,
            date_mode=request.dateMode or "EXACT",
        )

        cls._persist_activities(db, trip, suggestion, start_date_value)
        cls._persist_accommodations(db, trip, suggestion)
        cls._persist_flights(db, trip, suggestion)
        cls._persist_baggage(db, trip, suggestion, accept_language)
        cls._persist_breakdown_estimates(db, trip, suggestion, start_date_value)

        db.commit()
        db.refresh(trip)
        return cls._serialize(trip)

    # ── Resolution helpers ────────────────────────────────────────────

    @classmethod
    def _resolve_destination(
        cls, suggestion: dict, request: AcceptPlanRequest
    ) -> tuple[str, str | None]:
        """Pick the primary or user-selected alternative destination and
        resolve IATA server-side when the LLM did not include it."""
        dest_info = suggestion.get("destination", {})
        if isinstance(dest_info, dict):
            dest_city = dest_info.get("city", "")
            dest_country = dest_info.get("country", "")
            destination_name = f"{dest_city}, {dest_country}" if dest_country else dest_city
            destination_iata_value = dest_info.get("iata")
        else:
            destination_name = str(dest_info) if dest_info else "Inconnu"
            destination_iata_value = None

        idx = request.selectedDestinationIndex
        alternatives = suggestion.get("alternatives", [])
        if idx > 0 and alternatives:
            alt_idx = idx - 1
            if alt_idx < len(alternatives):
                chosen = alternatives[alt_idx]
                dest_city = chosen.get("city", "")
                dest_country = chosen.get("country", "")
                destination_name = f"{dest_city}, {dest_country}" if dest_country else dest_city
                destination_iata_value = chosen.get("iata")

        if not destination_iata_value and destination_name:
            resolved = cls._resolve_iata(destination_name.split(",")[0].strip())
            if resolved:
                logger.info(f"Resolved destination IATA: {destination_name} → {resolved}")
                destination_iata_value = resolved
        return destination_name, destination_iata_value

    @classmethod
    def _resolve_origin(cls, suggestion: dict, request: AcceptPlanRequest) -> str | None:
        """Prefer the LLM-provided `origin_iata`; fall back to offline
        resolution of the user-provided city."""
        origin_iata_value = suggestion.get("origin_iata")
        if not origin_iata_value and request.originCity:
            resolved = cls._resolve_iata(request.originCity)
            if resolved:
                logger.info(f"Resolved origin IATA: {request.originCity} → {resolved}")
                origin_iata_value = resolved
        return origin_iata_value

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
            # Offline resolution is best-effort; the trip can still be created
            # without an IATA (user fills it later).
            logger.warn("Offline IATA resolution failed", {"city": city_name})
        return None

    @staticmethod
    async def _fetch_cover_image(destination_name: str) -> str:
        """Unsplash cover with a static continent fallback."""
        from src.integrations.unsplash import unsplash_client

        cover = await unsplash_client.fetch_cover_image(destination_name)
        return cover or unsplash_client.get_fallback_url(destination_name)

    @staticmethod
    def _resolve_dates(request: AcceptPlanRequest, suggestion: dict) -> tuple[str, str]:
        """Safety net for month/flexible modes where the user didn't pick
        explicit dates — the trip still needs start/end."""
        start_date_value = request.startDate
        end_date_value = request.endDate
        if not start_date_value or not end_date_value:
            duration = suggestion.get("durationDays", 7) or 7
            start_date_value = start_date_value or str(date.today() + timedelta(days=30))
            end_date_value = end_date_value or str(
                date.fromisoformat(start_date_value) + timedelta(days=duration)
            )
        return start_date_value, end_date_value

    # ── Persistence helpers (one per domain) ─────────────────────────

    @staticmethod
    def _persist_activities(
        db: Session, trip: Trip, suggestion: dict, start_date_value: str
    ) -> None:
        activities_data = suggestion.get("activities", [])
        if not activities_data:
            return

        trip_start: date | None = None
        if start_date_value:
            with contextlib.suppress(ValueError):
                trip_start = date.fromisoformat(start_date_value)

        duration_days = suggestion.get("durationDays", len(activities_data)) or len(activities_data)

        for i, act in enumerate(activities_data):
            suggested_day = act.get("suggested_day")
            if suggested_day and isinstance(suggested_day, int):
                day_offset = (suggested_day - 1) % max(duration_days, 1)
            else:
                day_offset = i % max(duration_days, 1)

            activity_date = (
                trip_start + timedelta(days=day_offset)
                if trip_start
                else date.today() + timedelta(days=day_offset)
            )
            start_time_value = TIME_OF_DAY_MAP.get(act.get("time_of_day", ""))

            activity = Activity(
                trip_id=trip.id,
                title=act.get("title", f"Activite {i + 1}"),
                description=act.get("description", ""),
                date=activity_date,
                start_time=start_time_value,
                location=act.get("location"),
                category=act.get("category", "OTHER"),
                estimated_cost=act.get("estimatedCost"),
                validation_status=ValidationStatus.SUGGESTED,
            )
            db.add(activity)
            db.flush()

            estimated = act.get("estimatedCost")
            if estimated:
                db.add(
                    _build_budget_item(
                        trip_id=trip.id,
                        label=activity.title,
                        amount=float(estimated),
                        category=BudgetCategory.ACTIVITY,
                        source_type="activity",
                        source_id=activity.id,
                        item_date=activity_date,
                    )
                )

    @staticmethod
    def _persist_accommodations(db: Session, trip: Trip, suggestion: dict) -> None:
        accommodations_data = suggestion.get("accommodations", [])
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

            price_per_night = acc.get("price_per_night")
            if price_per_night and trip_nights > 0:
                db.add(
                    _build_budget_item(
                        trip_id=trip.id,
                        label=accommodation.name,
                        amount=float(price_per_night) * trip_nights,
                        category=BudgetCategory.ACCOMMODATION,
                        source_type="accommodation",
                        source_id=accommodation.id,
                    )
                )

    @classmethod
    def _persist_flights(cls, db: Session, trip: Trip, suggestion: dict) -> None:
        flight_data = suggestion.get("flight")
        if not (flight_data and isinstance(flight_data, dict)):
            return

        dep_airport, arr_airport = parse_flight_route(flight_data.get("route", ""))
        # Fallback: when the LLM omits the route string but the trip has IATA
        # codes, use those so the flight row ships with proper airports.
        if not dep_airport and trip.origin_iata:
            dep_airport = trip.origin_iata
        if not arr_airport and trip.destination_iata:
            arr_airport = trip.destination_iata

        outbound = _build_manual_flight(
            trip_id=trip.id,
            flight_data=flight_data,
            flight_type=FlightType.MAIN,
            dep_airport=dep_airport,
            arr_airport=arr_airport,
        )
        db.add(outbound)
        db.flush()
        cls._maybe_add_flight_budget(db, trip.id, outbound, flight_data)

        # Return leg: if the LLM omits the route, swap airports from outbound.
        return_data = suggestion.get("return_flight")
        if not (return_data and isinstance(return_data, dict)):
            return
        ret_dep, ret_arr = parse_flight_route(return_data.get("route", ""))
        if not ret_dep and not ret_arr:
            ret_dep, ret_arr = arr_airport, dep_airport

        return_flight = _build_manual_flight(
            trip_id=trip.id,
            flight_data=return_data,
            flight_type=FlightType.RETURN,
            dep_airport=ret_dep,
            arr_airport=ret_arr,
        )
        db.add(return_flight)
        db.flush()
        cls._maybe_add_flight_budget(db, trip.id, return_flight, return_data)

    @staticmethod
    def _maybe_add_flight_budget(
        db: Session, trip_id, flight: ManualFlight, flight_data: dict
    ) -> None:
        price = flight_data.get("price")
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

    @staticmethod
    def _persist_baggage(db: Session, trip: Trip, suggestion: dict, accept_language: str) -> None:
        ai_baggage = suggestion.get("baggage", [])
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

    # ── Budget breakdown estimation ──────────────────────────────────
    #
    # ``flight``, ``accommodation`` and ``activity`` already get budget
    # items via the dedicated persisters because they map to concrete
    # objects (a flight booking, a hotel offer, an activity entry).
    # ``food`` and ``transport`` have no concrete object — they are pure
    # estimates carried by the SSE ``budget`` event. Without this
    # method those two lines vanish at acceptance and the trip detail
    # screen shows a "prévisionnel" of just the flight (the user
    # regression report).
    #
    # We persist them as ``is_planned=True`` budget items so they
    # show up under "PRÉVISIONNEL" without polluting "RÉEL" (which
    # only counts ``is_planned=False`` actual spend).
    _BREAKDOWN_PERSISTED_CATEGORIES: tuple[str, ...] = ("food", "transport")
    _BREAKDOWN_LABELS_FR: dict[str, str] = {
        "food": "Repas estimés",
        "transport": "Transport estimé",
    }
    _BREAKDOWN_TO_ENUM: dict[str, BudgetCategory] = {
        "food": BudgetCategory.FOOD,
        "transport": BudgetCategory.TRANSPORT,
    }

    @classmethod
    def _persist_breakdown_estimates(
        cls,
        db: Session,
        trip: Trip,
        suggestion: dict,
        start_date_value: str | date | None,
    ) -> None:
        """Materialize the SSE ``budget`` breakdown into planned items.

        The Flutter wizard sends the pre-computed breakdown back inside
        ``suggestion["budget_breakdown"]`` (typed shape, EUR amounts).
        Falls back to ``suggestion["budget"]["estimation"]`` for
        backwards compatibility with payloads emitted before SMP-324.

        Categories that already have a per-object persister
        (``flight``, ``accommodation``, ``activity``) are skipped to
        avoid double-counting; only ``food`` and ``transport`` are
        materialized here.
        """
        breakdown = (
            suggestion.get("budget_breakdown")
            or (suggestion.get("budget") or {}).get("estimation")
            or {}
        )
        if not isinstance(breakdown, dict):
            return

        item_date = _coerce_iso_date(start_date_value)

        for key in cls._BREAKDOWN_PERSISTED_CATEGORIES:
            raw = breakdown.get(key)
            amount = _coerce_breakdown_amount(raw)
            if amount <= 0:
                continue
            db.add(
                _build_budget_item(
                    trip_id=trip.id,
                    label=cls._BREAKDOWN_LABELS_FR.get(key, key.title()),
                    amount=amount,
                    category=cls._BREAKDOWN_TO_ENUM[key].value,
                    source_type="estimation",
                    item_date=item_date,
                )
            )

    # ── Response serialization ───────────────────────────────────────

    @staticmethod
    def _serialize(trip: Trip) -> dict:
        return {
            "id": str(trip.id),
            "title": trip.title,
            "status": trip.status,
            "destinationName": trip.destination_name,
            "description": trip.description,
            "budgetTarget": trip.budget_target,
            "budgetEstimated": trip.budget_estimated,
            "origin": trip.origin,
            "startDate": str(trip.start_date) if trip.start_date else None,
            "endDate": str(trip.end_date) if trip.end_date else None,
        }
