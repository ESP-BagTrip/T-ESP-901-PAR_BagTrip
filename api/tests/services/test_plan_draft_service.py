"""Tests for :class:`PlanDraftService`.

Verifies the typed-DTO persistence path:

- A full TripDraftCommand fans out into Trip + Activity + Accommodation +
  ManualFlight + BudgetItem + BaggageItem rows.
- TRAIN legs land as TRANSPORT budget rows only — no fake ManualFlight
  (audit C7).
- Empty / placeholder rows are NOT persisted (audit C6).
- Per-day activity dating respects ``cmd.start_date`` + ``suggested_day``.
"""

from __future__ import annotations

import uuid
from types import SimpleNamespace
from unittest.mock import MagicMock

from src.services.full_plan_orchestrator import (
    AccommodationDraft,
    ActivityDraft,
    BaggageDraft,
    BudgetBreakdown,
    TransportLeg,
    TripDraftCommand,
    WeatherSummary,
)
from src.services.plan_draft_service import PlanDraftService


def _command(**overrides) -> TripDraftCommand:
    base = TripDraftCommand(
        origin_iata="CDG",
        origin_city="Paris",
        destination_iata="MRS",
        destination_city="Marseille",
        destination_country="France",
        destination_country_code="FR",
        destination_lat=43.44,
        destination_lon=5.22,
        start_date="2026-06-12",
        end_date="2026-06-15",
        duration_days=4,
        nb_travelers=3,
        target_budget=1500.0,
        locale="fr",
        cover_image_url="https://img",
        weather=WeatherSummary(
            avg_temp_c=25,
            min_temp_c=18,
            max_temp_c=32,
            rain_probability=10,
            description="Warm and sunny",
        ),
        activities=[
            ActivityDraft(
                title="Vieux-Port walk",
                description="Stroll the harbour.",
                category="CULTURE",
                estimated_cost=12.5,
                suggested_day=1,
                time_of_day="morning",
                location="Vieux-Port",
            ),
            ActivityDraft(
                title="Calanques boat",
                description="Coastal cruise.",
                category="NATURE",
                estimated_cost=30.0,
                suggested_day=2,
                time_of_day="afternoon",
                location="Port de la Pointe Rouge",
            ),
        ],
        accommodations=[
            AccommodationDraft(
                name="Hôtel Le Vieux-Port",
                hotel_id="HMRS001",
                rating=4.0,
                price_total=320.0,
                price_per_night=80.0,
                nights=4,
                adults=3,
                check_in="2026-06-12",
                check_out="2026-06-15",
                source="amadeus",
            )
        ],
        transport=[
            TransportLeg(
                mode="TRAIN",
                direction="OUTBOUND",
                origin_iata="CDG",
                destination_iata="MRS",
                origin_city="Paris",
                destination_city="Marseille",
                price=60.0,
                source="estimated",
            ),
            TransportLeg(
                mode="TRAIN",
                direction="RETURN",
                origin_iata="MRS",
                destination_iata="CDG",
                origin_city="Marseille",
                destination_city="Paris",
                price=60.0,
                source="estimated",
            ),
        ],
        baggage=[
            BaggageDraft(name="Passport", quantity=1, category="DOCUMENTS", reason="Required"),
        ],
        budget=BudgetBreakdown(food=540, currency="EUR"),
    )
    for k, v in overrides.items():
        setattr(base, k, v)
    return base


def _setup_db_and_user(monkeypatch) -> tuple[MagicMock, SimpleNamespace, list]:
    user = SimpleNamespace(id=uuid.uuid4())
    fake_trip = SimpleNamespace(
        id=uuid.uuid4(),
        status="DRAFT",
        start_date="2026-06-12",
        end_date="2026-06-15",
    )
    captured: list[object] = []
    db = MagicMock()
    db.add.side_effect = lambda obj: captured.append(obj)

    monkeypatch.setattr(
        "src.services.plan_draft_service.TripsService.create_trip",
        lambda **kwargs: fake_trip,
    )
    return db, user, captured


# ── Behaviour ─────────────────────────────────────────────────────────


def test_full_command_persists_everything(monkeypatch):
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()

    trip = PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    assert trip.status == "DRAFT"

    types = [type(o).__name__ for o in captured]
    # Phase B1 (SMP-325): activities are no longer mirrored as
    # BudgetItem rows, so the BudgetItem count drops by exactly the
    # number of priced activities.
    assert types.count("Activity") == 2
    assert types.count("Accommodation") == 1
    assert types.count("BaggageItem") == 1
    # ZERO ManualFlight rows because the trip is TRAIN-routed.
    assert types.count("ManualFlight") == 0
    # BudgetItem covers: 1 accommodation + 2 train + 1 food = 4
    # (the 2 activity costs are read from ``activities.estimated_cost``).
    assert types.count("BudgetItem") == 4
    activity_budget_items = [
        o
        for o in captured
        if type(o).__name__ == "BudgetItem" and o.category == "ACTIVITY"
    ]
    assert activity_budget_items == [], (
        "Activities must not produce mirrored BudgetItem rows after Phase B1"
    )
    db.commit.assert_called_once()
    db.refresh.assert_called_once_with(trip)


def test_train_legs_create_transport_budget_only_no_manual_flight(monkeypatch):
    """Audit C7 — TRAIN must never spawn a ManualFlight row."""
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.activities = []
    cmd.accommodations = []
    cmd.baggage = []
    cmd.budget = BudgetBreakdown()

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    types = [type(o).__name__ for o in captured]
    assert "ManualFlight" not in types
    # Two TransportLeg → two TRANSPORT budget rows.
    budget_items = [o for o in captured if type(o).__name__ == "BudgetItem"]
    assert len(budget_items) == 2
    assert all(b.category == "TRANSPORT" for b in budget_items)


def test_flight_legs_create_manual_flight_with_budget(monkeypatch):
    """FLIGHT mode persists ManualFlight rows + matching FLIGHT budget items."""
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.activities = []
    cmd.accommodations = []
    cmd.baggage = []
    cmd.transport = [
        TransportLeg(
            mode="FLIGHT",
            direction="OUTBOUND",
            carrier="AF",
            code="AF123",
            origin_iata="CDG",
            destination_iata="SIN",
            origin_city="Paris",
            destination_city="Singapore",
            departure_at="2026-07-04T22:00:00",
            arrival_at="2026-07-05T17:30:00",
            price=540.0,
            source="amadeus",
        ),
        TransportLeg(
            mode="FLIGHT",
            direction="RETURN",
            carrier="AF",
            code="AF124",
            origin_iata="SIN",
            destination_iata="CDG",
            origin_city="Singapore",
            destination_city="Paris",
            departure_at="2026-07-10T11:30:00",
            arrival_at="2026-07-10T19:00:00",
            price=540.0,
            source="amadeus",
        ),
    ]
    cmd.budget = BudgetBreakdown()

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    types = [type(o).__name__ for o in captured]
    assert types.count("ManualFlight") == 2
    flight_budgets = [
        o for o in captured if type(o).__name__ == "BudgetItem" and o.category == "FLIGHT"
    ]
    assert len(flight_budgets) == 2


def test_blank_accommodation_name_is_dropped(monkeypatch):
    """Audit C6 — never persist an Accommodation with a blank name."""
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.accommodations = [
        AccommodationDraft(name="", price_total=100.0, source="deferred"),
        AccommodationDraft(name="Real Hotel", price_total=200.0, source="amadeus"),
    ]
    cmd.activities = []
    cmd.baggage = []
    cmd.transport = []
    cmd.budget = BudgetBreakdown()

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    accommodations = [o for o in captured if type(o).__name__ == "Accommodation"]
    assert len(accommodations) == 1
    assert accommodations[0].name == "Real Hotel"


def test_activity_dating_respects_start_date_and_duration(monkeypatch):
    """``suggested_day=2`` on a trip starting 2026-06-12 lands on 2026-06-13."""
    from datetime import date

    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.accommodations = []
    cmd.transport = []
    cmd.baggage = []
    cmd.budget = BudgetBreakdown()

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    activities = [o for o in captured if type(o).__name__ == "Activity"]
    by_title = {a.title: a for a in activities}
    assert by_title["Vieux-Port walk"].date == date(2026, 6, 12)
    assert by_title["Calanques boat"].date == date(2026, 6, 13)
    # ``time_of_day`` maps to a real :class:`time`.
    assert by_title["Vieux-Port walk"].start_time is not None
    assert by_title["Vieux-Port walk"].start_time.hour == 9


def test_no_food_budget_when_amount_is_zero(monkeypatch):
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.activities = []
    cmd.accommodations = []
    cmd.transport = []
    cmd.baggage = []
    cmd.budget = BudgetBreakdown(food=0)

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    food_rows = [o for o in captured if type(o).__name__ == "BudgetItem" and o.category == "FOOD"]
    assert food_rows == []


def test_baggage_with_blank_name_is_dropped(monkeypatch):
    db, user, captured = _setup_db_and_user(monkeypatch)
    cmd = _command()
    cmd.activities = []
    cmd.accommodations = []
    cmd.transport = []
    cmd.budget = BudgetBreakdown()
    cmd.baggage = [
        BaggageDraft(name="", quantity=1, category="OTHER", reason=""),
        BaggageDraft(name="Passport", quantity=1, category="DOCUMENTS", reason="Required"),
    ]

    PlanDraftService.create_draft_from_command(db=db, user=user, cmd=cmd)
    baggage = [o for o in captured if type(o).__name__ == "BaggageItem"]
    assert len(baggage) == 1
    assert baggage[0].name == "Passport"
