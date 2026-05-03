"""Unit tests for PlanAcceptanceService.

The service is the single owner of the /v1/ai/plan-trip/accept flow. These
tests exercise the pure helpers + the persistence sub-methods by feeding
them a realistic suggestion payload (Barcelona 7 days) against a mocked
SQLAlchemy session.
"""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta
from unittest.mock import MagicMock

import pytest

from src.api.ai.plan_trip_schemas import AcceptPlanRequest
from src.enums import BudgetCategory, FlightType, ValidationStatus
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.services.plan_acceptance_service import (
    _DEFAULT_BAGGAGE_I18N,
    PlanAcceptanceService,
    combine_date_to_utc_datetime,
    compute_nights,
    get_default_baggage,
    parse_flight_route,
    parse_iso_datetime,
)

# ── Pure helpers ──────────────────────────────────────────────────────


class TestPureHelpers:
    def test_parse_flight_route_extracts_two_codes(self):
        assert parse_flight_route("CDG → BCN") == ("CDG", "BCN")
        assert parse_flight_route("cdg - bcn") == ("CDG", "BCN")
        assert parse_flight_route("CDG -> BCN") == ("CDG", "BCN")

    def test_parse_flight_route_partial(self):
        assert parse_flight_route("CDG only") == ("CDG", None)
        assert parse_flight_route("no codes") == (None, None)
        assert parse_flight_route("") == (None, None)

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
    """A DRAFT Trip fixture with dates + IATAs populated (as would be the
    case after `_create_trip`)."""
    t = MagicMock()
    t.id = uuid.uuid4()
    t.start_date = date(2026, 4, 23)
    t.end_date = date(2026, 4, 30)
    t.origin_iata = "CDG"
    t.destination_iata = "BCN"
    return t


class TestPersistActivities:
    def test_creates_activity_and_budget_line_when_cost(self, mock_db, trip):
        suggestion = {
            "durationDays": 7,
            "activities": [
                {
                    "title": "Tapas tour",
                    "description": "Born quarter",
                    "category": "FOOD",
                    "suggested_day": 2,
                    "time_of_day": "evening",
                    "estimatedCost": 45,
                }
            ],
        }

        PlanAcceptanceService._persist_activities(mock_db, trip, suggestion, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        activities = [x for x in added if isinstance(x, Activity)]
        budget_lines = [x for x in added if isinstance(x, BudgetItem)]

        assert len(activities) == 1
        assert activities[0].validation_status == ValidationStatus.SUGGESTED
        assert activities[0].date == date(2026, 4, 24)  # day 2
        assert len(budget_lines) == 1
        assert budget_lines[0].category == BudgetCategory.ACTIVITY
        assert float(budget_lines[0].amount) == 45.0
        assert budget_lines[0].is_planned is True
        assert budget_lines[0].source_type == "activity"

    def test_skips_budget_line_when_cost_missing(self, mock_db, trip):
        suggestion = {
            "durationDays": 7,
            "activities": [{"title": "Free walk"}],
        }

        PlanAcceptanceService._persist_activities(mock_db, trip, suggestion, "2026-04-23")

        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert any(isinstance(x, Activity) for x in added)
        assert not any(isinstance(x, BudgetItem) for x in added)

    def test_no_activities_is_noop(self, mock_db, trip):
        PlanAcceptanceService._persist_activities(mock_db, trip, {"activities": []}, "2026-04-23")
        assert mock_db.add.call_count == 0


class TestPersistAccommodations:
    def test_creates_accommodation_with_check_in_out_and_budget(self, mock_db, trip):
        suggestion = {
            "accommodations": [
                {"name": "Hotel Catalonia Plaza", "price_per_night": 120, "currency": "EUR"}
            ]
        }

        PlanAcceptanceService._persist_accommodations(mock_db, trip, suggestion)

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
        assert budget_lines[0].source_type == "accommodation"

    def test_skips_budget_when_price_missing(self, mock_db, trip):
        suggestion = {"accommodations": [{"name": "Hostel", "currency": "EUR"}]}

        PlanAcceptanceService._persist_accommodations(mock_db, trip, suggestion)

        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert len(added) == 1
        assert isinstance(added[0], Accommodation)

    def test_b23_budget_amount_is_per_night_times_nights_not_squared(self, mock_db, trip):
        """Pinning fix: persistance must treat `price_per_night` as per-night.

        Pre-04a, Flutter shipped the Amadeus stay total in this field and
        the service re-multiplied by trip nights, producing
        ``price_total × nights`` (× 7 inflation on a 7-night stay).
        Post-04a, callers must always send the per-night unit and the
        service stays the trustworthy multiplier.
        """
        # 7-night trip (fixture), 100 €/night → 700 € stay (not 4900 €).
        suggestion = {
            "accommodations": [
                {"name": "Hotel Test", "price_per_night": 100, "currency": "EUR"},
            ]
        }

        PlanAcceptanceService._persist_accommodations(mock_db, trip, suggestion)

        budget_lines = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], BudgetItem)
        ]
        assert len(budget_lines) == 1
        assert float(budget_lines[0].amount) == 700.0


class TestPersistFlights:
    def test_creates_main_and_return_flights_with_fallback_airports(self, mock_db, trip):
        """LLM omitted `route` on both legs — service must derive airports
        from trip IATAs for MAIN and swap them for RETURN."""
        suggestion = {
            "flight": {
                "price": 180,
                "source": "amadeus",
                "airline": "Vueling",
                "flight_number": "VY8017",
                "departure_date": "2026-04-23T10:15:00",
                "arrival_date": "2026-04-23T11:55:00",
                "duration": "PT1H40M",
            },
            "return_flight": {
                "source": "amadeus",
                "departure_date": "2026-04-30T18:00:00",
                "arrival_date": "2026-04-30T19:50:00",
            },
        }

        PlanAcceptanceService._persist_flights(mock_db, trip, suggestion)

        flights = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], ManualFlight)
        ]
        assert len(flights) == 2
        main, ret = flights
        assert main.flight_type == FlightType.MAIN
        assert main.departure_airport == "CDG"
        assert main.arrival_airport == "BCN"
        assert main.validation_status == ValidationStatus.SUGGESTED
        assert ret.flight_type == FlightType.RETURN
        assert ret.departure_airport == "BCN"
        assert ret.arrival_airport == "CDG"

    def test_flight_budget_line_created_when_price_present(self, mock_db, trip):
        suggestion = {
            "flight": {
                "route": "CDG → BCN",
                "price": 180,
                "source": "amadeus",
            },
        }
        PlanAcceptanceService._persist_flights(mock_db, trip, suggestion)

        budget_lines = [
            call.args[0]
            for call in mock_db.add.call_args_list
            if isinstance(call.args[0], BudgetItem)
        ]
        assert len(budget_lines) == 1
        assert budget_lines[0].category == BudgetCategory.FLIGHT
        assert float(budget_lines[0].amount) == 180.0

    def test_no_flight_is_noop(self, mock_db, trip):
        PlanAcceptanceService._persist_flights(mock_db, trip, {})
        assert mock_db.add.call_count == 0


class TestPersistBaggage:
    def test_uses_ai_baggage_when_available(self, mock_db, trip):
        suggestion = {
            "baggage": [
                {"name": "Swimsuit", "category": "CLOTHING", "quantity": 2},
            ]
        }
        PlanAcceptanceService._persist_baggage(mock_db, trip, suggestion, "en")
        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert len(added) == 1
        assert added[0].name == "Swimsuit"

    def test_falls_back_to_default_when_ai_omits_baggage(self, mock_db, trip):
        PlanAcceptanceService._persist_baggage(mock_db, trip, {}, "fr")
        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert len(added) == len(_DEFAULT_BAGGAGE_I18N["fr"])
        assert added[0].name == "Passeport"

    def test_accept_language_locale_prefix(self, mock_db, trip):
        """Only the two-letter prefix matters (e.g. `fr-FR,fr;q=0.9`)."""
        PlanAcceptanceService._persist_baggage(mock_db, trip, {}, "fr-FR,fr;q=0.9")
        added = [call.args[0] for call in mock_db.add.call_args_list]
        assert added[0].name == "Passeport"


class TestPersistBreakdownEstimates:
    """The SSE budget event ships estimation lines (food, transport,
    accommodation, activity) that have no concrete object to attach to.
    Without ``_persist_breakdown_estimates`` they vanish at acceptance
    and the trip detail "PRÉVISIONNEL" only shows the flight line —
    the regression the user spotted on the Tokyo trip."""

    @staticmethod
    def _by_category(mock_db):
        return {
            call.args[0].category: call.args[0]
            for call in mock_db.add.call_args_list
        }

    def test_persists_food_and_transport_lines_from_breakdown(self, mock_db, trip):
        suggestion = {
            "budget_breakdown": {
                "flight": {"amount": 2101, "source": "amadeus"},
                "accommodation": {"amount": 0, "source": "deferred"},
                "food": {"amount": 315, "source": "per_diem"},
                "transport": {"amount": 126, "source": "per_diem"},
                "activity": {"amount": 225, "source": "gathered_data"},
            }
        }
        PlanAcceptanceService._persist_breakdown_estimates(
            mock_db, trip, suggestion, date(2026, 5, 3)
        )
        added = self._by_category(mock_db)
        assert "FOOD" in added
        assert "TRANSPORT" in added
        # Flight / accommodation / activity remain handled by their dedicated
        # persisters, so this method must NOT double-count them.
        assert "FLIGHT" not in added
        assert "ACCOMMODATION" not in added
        assert "ACTIVITY" not in added
        assert added["FOOD"].amount == 315
        assert added["FOOD"].is_planned is True
        assert added["FOOD"].source_type == "estimation"
        assert added["FOOD"].date == date(2026, 5, 3)
        assert added["TRANSPORT"].amount == 126

    def test_skips_zero_or_missing_breakdown_lines(self, mock_db, trip):
        suggestion = {
            "budget_breakdown": {
                "food": {"amount": 0, "source": "per_diem"},
                # transport intentionally omitted
            }
        }
        PlanAcceptanceService._persist_breakdown_estimates(
            mock_db, trip, suggestion, None
        )
        assert mock_db.add.call_args_list == []

    def test_falls_back_to_legacy_budget_estimation_shape(self, mock_db, trip):
        # Pre-SMP-324 SSE shape was ``{"budget": {"estimation": {...}}}``.
        suggestion = {
            "budget": {
                "estimation": {
                    "food": 200,
                    "transport": 60,
                }
            }
        }
        PlanAcceptanceService._persist_breakdown_estimates(
            mock_db, trip, suggestion, date(2026, 5, 3)
        )
        added = self._by_category(mock_db)
        assert added["FOOD"].amount == 200
        assert added["TRANSPORT"].amount == 60

    def test_no_breakdown_is_noop(self, mock_db, trip):
        PlanAcceptanceService._persist_breakdown_estimates(mock_db, trip, {}, None)
        assert mock_db.add.call_args_list == []

    def test_malformed_amount_silently_drops_line(self, mock_db, trip):
        suggestion = {
            "budget_breakdown": {
                "food": {"amount": "not-a-number"},
                "transport": "garbage",
            }
        }
        PlanAcceptanceService._persist_breakdown_estimates(
            mock_db, trip, suggestion, None
        )
        assert mock_db.add.call_args_list == []


class TestResolveDates:
    def test_passes_through_user_selected_dates(self):
        req = AcceptPlanRequest(suggestion={}, startDate="2026-04-23", endDate="2026-04-30")
        start, end = PlanAcceptanceService._resolve_dates(req, {"durationDays": 7})
        assert start == "2026-04-23"
        assert end == "2026-04-30"

    def test_falls_back_when_dates_missing(self):
        req = AcceptPlanRequest(suggestion={})
        start, end = PlanAcceptanceService._resolve_dates(req, {"durationDays": 5})
        today = date.today()
        assert date.fromisoformat(start) == today + timedelta(days=30)
        assert date.fromisoformat(end) == today + timedelta(days=35)


class TestSerialize:
    def test_returns_legacy_response_shape(self):
        t = MagicMock()
        t.id = uuid.UUID("103403bc-19e9-451d-b6d1-ba047051902c")
        t.title = "Voyage à Barcelone"
        t.status = "DRAFT"
        t.destination_name = "Barcelone"
        t.description = None
        t.budget_target = 1200
        t.origin = "AI"
        t.start_date = date(2026, 4, 23)
        t.end_date = date(2026, 4, 30)
        payload = PlanAcceptanceService._serialize(t)
        assert payload["id"] == str(t.id)
        assert payload["startDate"] == "2026-04-23"
        assert payload["origin"] == "AI"
