"""Unit tests for PlanDraftService.

SMP-324 — the service is the single owner of the SSE → DRAFT Trip
persistence flow. It consumes a finished LangGraph ``TripPlanState``
and writes the canonical Trip + Activity / Accommodation / ManualFlight /
BaggageItem / BudgetItem rows. The wizard never re-uploads anything;
confirming the trip is just ``PATCH /trips/{id}/status``.

These tests exercise the pure helpers + the persistence sub-methods
against a mocked SQLAlchemy session. ``create_draft_from_state`` itself
is covered end-to-end (with the Unsplash + IATA fetches stubbed).
"""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.enums import BudgetCategory, FlightType, ValidationStatus
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.services.plan_draft_service import (
    _DEFAULT_BAGGAGE_I18N,
    PlanDraftService,
    combine_date_to_utc_datetime,
    compute_nights,
    get_default_baggage,
    parse_iso_datetime,
)

# ── Pure helpers ──────────────────────────────────────────────────────


class TestPureHelpers:
    def test_parse_iso_datetime(self):
        assert parse_iso_datetime("2026-04-23T10:15:00") == datetime(2026, 4, 23, 10, 15)
        assert parse_iso_datetime("") is None
        assert parse_iso_datetime(None) is None
        assert parse_iso_datetime("not-a-date") is None

    def test_compute_nights(self):
        assert compute_nights(date(2026, 4, 23), date(2026, 4, 30)) == 7
        assert compute_nights(None, date(2026, 4, 30)) == 0
        assert compute_nights(date(2026, 4, 30), date(2026, 4, 23)) == 0

    def test_combine_date_to_utc_datetime(self):
        result = combine_date_to_utc_datetime(date(2026, 4, 23))
        assert result == datetime(2026, 4, 23, 0, 0, tzinfo=UTC)
        assert combine_date_to_utc_datetime(None) is None

    def test_default_baggage_lang_fallback(self):
        assert get_default_baggage("fr")[0]["name"] == "Passeport"
        assert get_default_baggage("en")[0]["name"] == "Passport"
        assert get_default_baggage("de") == _DEFAULT_BAGGAGE_I18N["en"]


# ── Service persistence sub-methods ──────────────────────────────────


@pytest.fixture
def mock_db():
    return MagicMock()


@pytest.fixture
def trip():
    """A DRAFT Trip fixture with dates + IATAs populated (post-create)."""
    t = MagicMock()
    t.id = uuid.uuid4()
    t.start_date = date(2026, 4, 23)
    t.end_date = date(2026, 4, 30)
    t.origin_iata = "CDG"
    t.destination_iata = "BCN"
    return t


class TestPersistActivities:
    def test_creates_dated_activity_and_budget_line_with_culture_category(self, mock_db, trip):
        state = {
            "duration_days": 7,
            "activities": [
                {
                    "title": "Sagrada Família",
                    "description": "Architecture iconique",
                    "category": "CULTURE",
                    "suggested_day": 2,
                    "time_of_day": "morning",
                    "estimated_cost": 26,
                }
            ],
        }

        PlanDraftService._persist_activities(mock_db, trip, state, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        activities = [x for x in added if isinstance(x, Activity)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert len(activities) == 1
        assert activities[0].validation_status == ValidationStatus.SUGGESTED
        assert activities[0].date == date(2026, 4, 24)  # day 2
        assert activities[0].category == "CULTURE"
        assert len(budget_lines) == 1
        assert budget_lines[0].category == BudgetCategory.ACTIVITY
        assert float(budget_lines[0].amount) == 26.0
        assert budget_lines[0].source_type == "activity"
        # Phase B — budget lines born from an AI suggestion shadow the
        # underlying Activity / Accommodation / ManualFlight, so they
        # must be SUGGESTED themselves and feed the unified validate UI.
        assert budget_lines[0].validation_status == ValidationStatus.SUGGESTED.value

    def test_food_recommendation_routes_to_food_budget_bucket(self, mock_db, trip):
        state = {
            "duration_days": 7,
            "activities": [
                {
                    "title": "Tapas tour",
                    "description": "Born quarter",
                    "category": "FOOD",
                    "estimated_cost": 45,
                }
            ],
        }

        PlanDraftService._persist_activities(mock_db, trip, state, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        activities = [x for x in added if isinstance(x, Activity)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert activities[0].date is None  # undated by design
        assert activities[0].category == "FOOD"
        assert budget_lines[0].category == BudgetCategory.FOOD
        assert float(budget_lines[0].amount) == 45.0
        assert budget_lines[0].validation_status == ValidationStatus.SUGGESTED.value

    def test_transport_recommendation_routes_to_transport_budget_bucket(self, mock_db, trip):
        state = {
            "duration_days": 7,
            "activities": [
                {
                    "title": "JR Pass 7 jours",
                    "category": "TRANSPORT",
                    "estimated_cost": 240,
                }
            ],
        }

        PlanDraftService._persist_activities(mock_db, trip, state, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]
        activities = [x for x in added if isinstance(x, Activity)]

        assert activities[0].date is None
        assert activities[0].category == "TRANSPORT"
        assert budget_lines[0].category == BudgetCategory.TRANSPORT
        assert float(budget_lines[0].amount) == 240.0
        assert budget_lines[0].validation_status == ValidationStatus.SUGGESTED.value

    def test_skips_budget_line_when_cost_missing(self, mock_db, trip):
        state = {
            "duration_days": 7,
            "activities": [
                {
                    "title": "Free walk",
                    "category": "CULTURE",
                    "suggested_day": 1,
                    "time_of_day": "morning",
                }
            ],
        }

        PlanDraftService._persist_activities(mock_db, trip, state, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert any(isinstance(x, Activity) for x in added)
        assert not any(isinstance(x, BudgetItem) for x in added)

    def test_no_activities_is_noop(self, mock_db, trip):
        PlanDraftService._persist_activities(mock_db, trip, {"activities": []}, "2026-04-23")
        assert mock_db.add.call_count == 0


class TestPersistAccommodations:
    def test_creates_accommodation_with_check_in_out_and_budget(self, mock_db, trip):
        state = {
            "accommodations": [
                {"name": "Hotel Catalonia Plaza", "price_per_night": 120, "currency": "EUR"}
            ]
        }

        PlanDraftService._persist_accommodations(mock_db, trip, state)

        added = [call.args[0] for call in mock_db.add.call_args_list]
        accommodations = [x for x in added if isinstance(x, Accommodation)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert len(accommodations) == 1
        accommodation = accommodations[0]
        assert accommodation.name == "Hotel Catalonia Plaza"
        assert accommodation.check_in == datetime(2026, 4, 23, 0, 0, tzinfo=UTC)
        assert accommodation.check_out == datetime(2026, 4, 30, 0, 0, tzinfo=UTC)
        assert accommodation.validation_status == ValidationStatus.SUGGESTED

        assert len(budget_lines) == 1
        assert budget_lines[0].category == BudgetCategory.ACCOMMODATION
        assert float(budget_lines[0].amount) == 120.0 * 7
        assert budget_lines[0].validation_status == ValidationStatus.SUGGESTED.value

    def test_skips_budget_when_price_missing(self, mock_db, trip):
        state = {"accommodations": [{"name": "Hostel", "currency": "EUR"}]}

        PlanDraftService._persist_accommodations(mock_db, trip, state)

        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert len(added) == 1
        assert isinstance(added[0], Accommodation)

    def test_uses_price_total_when_provided(self, mock_db, trip):
        """SMP-324 — review breakdown reads ``price_total`` directly
        (Amadeus stay total). Persistence must use the same precedence
        so phase 1 and phase 2 stay aligned."""
        state = {
            "accommodations": [
                {
                    "name": "Hotel Tokyo",
                    "price_total": 950,
                    "price_per_night": 120,  # would yield 840 if used naively
                    "currency": "EUR",
                }
            ]
        }

        PlanDraftService._persist_accommodations(mock_db, trip, state)

        budget_lines = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], BudgetItem)
        ]
        assert float(budget_lines[0].amount) == 950.0


class TestPersistFlights:
    def test_creates_main_flight_from_offer(self, mock_db, trip):
        """Offer payloads carry ``departure`` / ``arrival`` (Amadeus
        shape), not the legacy ``departure_date``. Mapper bridges it."""
        state = {
            "flight_offers": [
                {
                    "airline": "VY",
                    "flight_number": "VY 8017",
                    "price": 180.0,
                    "currency": "EUR",
                    "departure": "2026-04-23T10:15:00",
                    "arrival": "2026-04-23T11:55:00",
                    "duration": "PT1H40M",
                    "origin_iata": "CDG",
                    "destination_iata": "BCN",
                    "source": "amadeus",
                }
            ]
        }

        PlanDraftService._persist_flights(mock_db, trip, state)

        added = [call.args[0] for call in mock_db.add.call_args_list]
        flights = [x for x in added if isinstance(x, ManualFlight)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert len(flights) == 1
        outbound = flights[0]
        assert outbound.flight_type == FlightType.MAIN
        assert outbound.airline == "VY"
        assert outbound.departure_airport == "CDG"
        assert outbound.arrival_airport == "BCN"
        assert outbound.departure_date == datetime(2026, 4, 23, 10, 15)
        assert outbound.validation_status == ValidationStatus.SUGGESTED

        assert len(budget_lines) == 1
        assert budget_lines[0].category == BudgetCategory.FLIGHT
        assert float(budget_lines[0].amount) == 180.0
        assert budget_lines[0].validation_status == ValidationStatus.SUGGESTED.value

    def test_creates_return_leg_when_offer_carries_return_fields(self, mock_db, trip):
        state = {
            "flight_offers": [
                {
                    "price": 300.0,
                    "currency": "EUR",
                    "departure": "2026-04-23T10:00:00",
                    "arrival": "2026-04-23T12:00:00",
                    "return_departure": "2026-04-30T18:00:00",
                    "return_arrival": "2026-04-30T20:00:00",
                    "origin_iata": "CDG",
                    "destination_iata": "BCN",
                    "source": "amadeus",
                }
            ]
        }

        PlanDraftService._persist_flights(mock_db, trip, state)

        added = [call.args[0] for call in mock_db.add.call_args_list]
        flights = [x for x in added if isinstance(x, ManualFlight)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert len(flights) == 2
        types = {f.flight_type for f in flights}
        assert types == {FlightType.MAIN, FlightType.RETURN}
        return_flight = next(f for f in flights if f.flight_type == FlightType.RETURN)
        assert return_flight.departure_airport == "BCN"
        assert return_flight.arrival_airport == "CDG"
        # Single Amadeus offer ships one whole-trip price; budgeting it
        # twice would inflate the round-trip total.
        assert len(budget_lines) == 1
        assert float(budget_lines[0].amount) == 300.0

    def test_no_flight_offers_is_noop(self, mock_db, trip):
        PlanDraftService._persist_flights(mock_db, trip, {"flight_offers": []})
        assert mock_db.add.call_count == 0


class TestPersistBaggage:
    def test_uses_ai_baggage_when_available(self, mock_db, trip):
        state = {
            "baggage_items": [
                {"name": "Passport", "category": "DOCUMENTS", "quantity": 1},
                {"name": "Charger", "category": "ELECTRONICS", "quantity": 2},
            ]
        }

        PlanDraftService._persist_baggage(mock_db, trip, state, "fr")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        baggage = [x for x in added if isinstance(x, BaggageItem)]
        assert len(baggage) == 2
        assert baggage[0].name == "Passport"
        assert baggage[1].quantity == 2

    def test_falls_back_to_default_when_state_omits_baggage(self, mock_db, trip):
        PlanDraftService._persist_baggage(mock_db, trip, {"baggage_items": []}, "en")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        baggage = [x for x in added if isinstance(x, BaggageItem)]
        assert len(baggage) == 6
        assert baggage[0].name == "Passport"  # English default

    def test_accept_language_locale_prefix(self, mock_db, trip):
        PlanDraftService._persist_baggage(mock_db, trip, {}, "fr-FR,fr;q=0.9")

        baggage = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], BaggageItem)
        ]
        assert baggage[0].name == "Passeport"


# ── End-to-end create_draft_from_state ───────────────────────────────


class TestCreateDraftFromState:
    @pytest.mark.asyncio
    async def test_persists_trip_with_status_draft_and_returns_id(self, mock_db):
        """The wizard never re-uploads the suggestion; the SSE finishing
        is enough to get a DRAFT trip in DB and a tripId back to the
        client. This is the architectural pivot of SMP-324."""
        user = MagicMock()
        user.id = uuid.uuid4()
        user.full_name = "Test User"

        state = {
            "selected_destination": {"city": "Tokyo", "country": "Japan", "iata": "HND"},
            "origin_iata": "CDG",
            "departure_date": "2026-06-01",
            "return_date": "2026-06-08",
            "duration_days": 7,
            "nb_travelers": 1,
            "target_budget": 3000.0,
            "date_mode": "EXACT",
            "activities": [],
            "accommodations": [],
            "flight_offers": [],
            "baggage_items": [],
            "budget_estimation": {},
            "weather_data": {},
            "locale": "fr",
        }

        fake_trip = MagicMock()
        fake_trip.id = uuid.uuid4()
        fake_trip.status = "DRAFT"
        fake_trip.start_date = date(2026, 6, 1)
        fake_trip.end_date = date(2026, 6, 8)
        fake_trip.origin_iata = "CDG"
        fake_trip.destination_iata = "HND"

        with (
            patch(
                "src.services.plan_draft_service.TripsService.create_trip",
                return_value=fake_trip,
            ) as create_trip_mock,
            patch(
                "src.services.plan_draft_service.PlanDraftService._fetch_cover_image",
                new=AsyncMock(return_value="https://images.example/tokyo.jpg"),
            ),
        ):
            trip = await PlanDraftService.create_draft_from_state(
                db=mock_db,
                user=user,
                state=state,
                accept_language="fr",
            )

        assert trip is fake_trip
        # The Trip is created with origin="AI" so the home distinguishes
        # AI-generated drafts from manual ones.
        kwargs = create_trip_mock.call_args.kwargs
        assert kwargs["origin"] == "AI"
        assert kwargs["title"] == "Voyage à Tokyo, Japan"
        assert kwargs["destination_iata"] == "HND"
        assert kwargs["origin_iata"] == "CDG"
        assert kwargs["budget_target"] == 3000.0
        assert kwargs["start_date"] == "2026-06-01"
        assert kwargs["end_date"] == "2026-06-08"
        # Default baggage seeded so the wizard can immediately render
        # the bagage tab even when the agent didn't surface anything.
        baggage = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], BaggageItem)
        ]
        assert len(baggage) == 6  # FR defaults from get_default_baggage("fr")

    @pytest.mark.asyncio
    async def test_synthesizes_dates_when_state_missing_them(self, mock_db):
        """Flexible / month modes can reach this stage without explicit
        dates; the service must still produce a valid draft so the
        wizard never breaks on a missing field."""
        user = MagicMock()
        user.id = uuid.uuid4()

        state = {
            "selected_destination": {"city": "Lisbon", "country": "Portugal"},
            "duration_days": 5,
            "activities": [],
            "accommodations": [],
            "flight_offers": [],
            "baggage_items": [],
        }

        fake_trip = MagicMock(
            id=uuid.uuid4(),
            status="DRAFT",
            # Real ``date`` instances so ``compute_nights`` (called by the
            # accommodations sub-method) doesn't choke on a MagicMock.
            start_date=date(2026, 6, 1),
            end_date=date(2026, 6, 6),
            origin_iata=None,
            destination_iata=None,
        )
        with (
            patch(
                "src.services.plan_draft_service.TripsService.create_trip",
                return_value=fake_trip,
            ) as create_trip_mock,
            patch(
                "src.services.plan_draft_service.PlanDraftService._fetch_cover_image",
                new=AsyncMock(return_value=""),
            ),
        ):
            await PlanDraftService.create_draft_from_state(
                db=mock_db, user=user, state=state, accept_language="en"
            )

        kwargs = create_trip_mock.call_args.kwargs
        # Both dates must be set; precise values come from the helper.
        assert kwargs["start_date"]
        assert kwargs["end_date"]
        start = date.fromisoformat(kwargs["start_date"])
        end = date.fromisoformat(kwargs["end_date"])
        assert (end - start).days == 5
