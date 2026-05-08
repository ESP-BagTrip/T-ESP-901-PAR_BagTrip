"""Persist a :class:`TripDraftCommand` as a DRAFT Trip + children.

Replaces :class:`PlanAcceptanceService` (and its loose ``suggestion``
dict input) with a single typed entry-point. The route that used to
accept a client-side plan dict is no longer needed; the SSE pipeline
now persists server-side at the end of a successful run.

Per-domain helpers (``_persist_activities``, ``_persist_accommodations``,
``_persist_transport``, ``_persist_baggage``) translate the dataclass
fields to ORM rows with a single ``flush`` per child. The shared
``BudgetItem`` rows go through :func:`_build_budget_item`.
"""

from __future__ import annotations

from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal

from sqlalchemy.orm import Session

from src.enums import BudgetCategory, FlightType, TripOrigin, ValidationStatus
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.models.trip import Trip
from src.models.user import User
from src.services.full_plan_orchestrator import (
    ActivityDraft,
    BudgetBreakdown,
    TransportLeg,
    TripDraftCommand,
)
from src.services.trips_service import TripsService
from src.utils.logger import logger

# ── Public API ────────────────────────────────────────────────────────


_TIME_OF_DAY_MAP: dict[str, time] = {
    "morning": time(9, 0),
    "afternoon": time(14, 0),
    "evening": time(19, 0),
}


class PlanDraftService:
    """Stateless. Use :meth:`create_draft_from_command` per draft."""

    @classmethod
    def create_draft_from_command(
        cls,
        *,
        db: Session,
        user: User,
        cmd: TripDraftCommand,
    ) -> Trip:
        """Create the Trip + its children inside a single transaction.

        The caller (``TripPlannerService.stream_plan`` after Phase 3c)
        commits the session itself; we ``flush`` after each child so
        FK-bearing rows can reference the parent IDs but never leave
        the session in a partially-committed state.
        """
        title = cls._compose_title(cmd)
        trip = TripsService.create_trip(
            db=db,
            user_id=user.id,
            title=title,
            origin_iata=cmd.origin_iata,
            destination_iata=cmd.destination_iata,
            destination_name=cls._compose_destination_name(cmd),
            description=cls._compose_description(cmd),
            budget_target=cmd.target_budget,
            start_date=cmd.start_date or None,
            end_date=cmd.end_date or None,
            origin=TripOrigin.AI,
            cover_image_url=cmd.cover_image_url,
            date_mode="EXACT",
            nb_travelers=cmd.nb_travelers,
        )

        cls._persist_activities(db, trip, cmd)
        cls._persist_accommodations(db, trip, cmd)
        cls._persist_transport(db, trip, cmd)
        cls._persist_baggage(db, trip, cmd)
        cls._persist_food_and_local_transport_budget(db, trip, cmd)

        db.commit()
        db.refresh(trip)
        logger.info(
            "PlanDraftService persisted trip",
            {
                "trip_id": str(trip.id),
                "destination": cmd.destination_iata,
                "duration_days": cmd.duration_days,
                "activities": len(cmd.activities),
                "accommodations": len(cmd.accommodations),
                "transport_legs": len(cmd.transport),
                "baggage_items": len(cmd.baggage),
            },
        )
        return trip

    # ── Title / description / destination name ────────────────────────

    @staticmethod
    def _compose_title(cmd: TripDraftCommand) -> str:
        city = cmd.destination_city or "destination"
        return f"Voyage à {city}"

    @staticmethod
    def _compose_destination_name(cmd: TripDraftCommand) -> str:
        if cmd.destination_country:
            return f"{cmd.destination_city}, {cmd.destination_country}"
        return cmd.destination_city or "Inconnu"

    @staticmethod
    def _compose_description(cmd: TripDraftCommand) -> str:
        return f"AI-planned trip to {cmd.destination_city}"

    # ── Activities + per-activity budget items ────────────────────────

    @classmethod
    def _persist_activities(cls, db: Session, trip: Trip, cmd: TripDraftCommand) -> None:
        # Phase B1 (SMP-325): ``Activity`` is the single source of truth
        # for activity costs. We no longer mirror each row into a
        # ``BudgetItem`` with ``source_type="activity"`` — the budget
        # summary projects ``Activity.estimated_cost`` directly, and the
        # mobile budget panel renders activities as virtual rows. This
        # removes the silent x2 inflation of ``total_spent`` and the UX
        # confusion of seeing every activity twice (once per tab).
        if not cmd.activities:
            return
        trip_start = _parse_date(cmd.start_date)
        for act in cmd.activities:
            activity_date = cls._activity_date(act, trip_start, cmd.duration_days)
            start_time = _TIME_OF_DAY_MAP.get(act.time_of_day or "")
            row = Activity(
                trip_id=trip.id,
                title=act.title or "Activité",
                description=act.description or "",
                date=activity_date,
                start_time=start_time,
                location=act.location or None,
                category=act.category or "OTHER",
                estimated_cost=Decimal(str(act.estimated_cost)) if act.estimated_cost else None,
                validation_status=ValidationStatus.SUGGESTED,
            )
            db.add(row)
            db.flush()

    @staticmethod
    def _activity_date(
        act: ActivityDraft, trip_start: date | None, duration_days: int
    ) -> date | None:
        if act.suggested_day is None:
            return None
        if trip_start is None:
            return None
        # ``suggested_day`` is 1-based.
        offset = max(act.suggested_day - 1, 0)
        if duration_days > 0:
            offset = min(offset, duration_days - 1)
        return trip_start + timedelta(days=offset)

    # ── Accommodations + budget item ──────────────────────────────────

    @staticmethod
    def _persist_accommodations(db: Session, trip: Trip, cmd: TripDraftCommand) -> None:
        if not cmd.accommodations:
            return
        check_in_dt = _date_to_utc(_parse_date(cmd.start_date))
        check_out_dt = _date_to_utc(_parse_date(cmd.end_date))
        for acc in cmd.accommodations:
            # Audit C6 — never persist a placeholder with a blank name.
            if not (acc.name or "").strip():
                continue
            row = Accommodation(
                trip_id=trip.id,
                name=acc.name,
                address=None,
                check_in=check_in_dt,
                check_out=check_out_dt,
                price_per_night=Decimal(str(acc.price_per_night))
                if acc.price_per_night is not None
                else None,
                currency=acc.currency,
                notes=f"Source: {acc.source}",
                validation_status=ValidationStatus.SUGGESTED,
            )
            db.add(row)
            db.flush()
            if acc.price_total is not None and acc.price_total > 0:
                db.add(
                    _build_budget_item(
                        trip_id=trip.id,
                        label=row.name,
                        amount=float(acc.price_total),
                        category=BudgetCategory.ACCOMMODATION,
                        source_type="accommodation",
                        source_id=row.id,
                    )
                )

    # ── Transport (FLIGHT → ManualFlight, TRAIN → budget only) ────────

    @classmethod
    def _persist_transport(cls, db: Session, trip: Trip, cmd: TripDraftCommand) -> None:
        if not cmd.transport:
            return
        for leg in cmd.transport:
            if leg.mode == "FLIGHT":
                cls._persist_flight_leg(db, trip, leg)
            elif leg.mode == "TRAIN":
                cls._persist_train_leg(db, trip, leg)

    @staticmethod
    def _persist_flight_leg(db: Session, trip: Trip, leg: TransportLeg) -> None:
        flight_type = FlightType.MAIN if leg.direction == "OUTBOUND" else FlightType.RETURN
        row = ManualFlight(
            trip_id=trip.id,
            flight_number=leg.code or "TBD",
            airline=leg.carrier or None,
            departure_airport=leg.origin_iata or None,
            arrival_airport=leg.destination_iata or None,
            departure_date=_parse_iso_datetime(leg.departure_at),
            arrival_date=_parse_iso_datetime(leg.arrival_at),
            price=Decimal(str(leg.price)) if leg.price is not None else None,
            currency=leg.currency or "EUR",
            notes=f"AI suggestion ({leg.source})",
            flight_type=flight_type,
            validation_status=ValidationStatus.SUGGESTED,
        )
        db.add(row)
        db.flush()
        if leg.price is not None and leg.price > 0:
            label = f"{leg.direction.title()} flight {leg.origin_iata}→{leg.destination_iata}"
            db.add(
                _build_budget_item(
                    trip_id=trip.id,
                    label=label,
                    amount=float(leg.price),
                    category=BudgetCategory.FLIGHT,
                    source_type="manual_flight",
                    source_id=row.id,
                )
            )

    @staticmethod
    def _persist_train_leg(db: Session, trip: Trip, leg: TransportLeg) -> None:
        # No ``ManualTrain`` model yet — train legs land as a TRANSPORT
        # budget line so the user sees the cost without us spawning a
        # fake ManualFlight (audit C7: every FLIGHT row in budget must
        # have a real flight; TRAIN rows belong to TRANSPORT).
        if leg.price is None or leg.price <= 0:
            return
        label = (
            f"{leg.direction.title()} train {leg.origin_city or leg.origin_iata}"
            f" → {leg.destination_city or leg.destination_iata}"
        )
        db.add(
            _build_budget_item(
                trip_id=trip.id,
                label=label,
                amount=float(leg.price),
                category=BudgetCategory.TRANSPORT,
                source_type="train",
                source_id=None,
            )
        )

    # ── Baggage ───────────────────────────────────────────────────────

    @staticmethod
    def _persist_baggage(db: Session, trip: Trip, cmd: TripDraftCommand) -> None:
        if not cmd.baggage:
            return
        for item in cmd.baggage:
            if not (item.name or "").strip():
                continue
            db.add(
                BaggageItem(
                    trip_id=trip.id,
                    name=item.name,
                    quantity=max(item.quantity, 1),
                    category=item.category or "OTHER",
                    notes=item.reason or None,
                )
            )

    # ── Food + local transport (deterministic, no entity rows) ────────

    @staticmethod
    def _persist_food_and_local_transport_budget(
        db: Session, trip: Trip, cmd: TripDraftCommand
    ) -> None:
        budget = cmd.budget
        if budget.food and budget.food > 0:
            db.add(
                _build_budget_item(
                    trip_id=trip.id,
                    label="Food (estimated)",
                    amount=float(budget.food),
                    category=BudgetCategory.FOOD,
                    source_type="estimated",
                )
            )
        # The local transport allowance (per-day metro / taxi band) is
        # already folded into ``budget.transport`` together with the
        # main legs; we don't double-book a separate row to keep the
        # budget tab tidy. Phase 3d refines the breakdown surface.


# ── Module-level helpers ──────────────────────────────────────────────


def _parse_date(value: str | None) -> date | None:
    if not value:
        return None
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def _parse_iso_datetime(value: object) -> datetime | None:
    if not value or not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value)
    except ValueError:
        return None


def _date_to_utc(value: date | None) -> datetime | None:
    if value is None:
        return None
    return datetime.combine(value, time.min, tzinfo=UTC)


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
    return BudgetItem(
        trip_id=trip_id,
        label=label,
        amount=amount,
        category=category,
        date=item_date,
        is_planned=True,
        source_type=source_type,
        source_id=source_id,
        validation_status=ValidationStatus.SUGGESTED,
    )


# Re-export for symmetry with the rest of the services package.
__all__ = ["PlanDraftService", "BudgetBreakdown"]
