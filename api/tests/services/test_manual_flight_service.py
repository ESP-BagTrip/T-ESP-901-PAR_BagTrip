"""Unit tests for `ManualFlightService`."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from unittest.mock import patch

import pytest

from src.models.budget_item import BudgetItem
from src.models.manual_flight import ManualFlight
from src.services.manual_flight_service import ManualFlightService
from src.utils.errors import AppError


class TestCreate:
    def test_creates_flight_and_budget_item_when_priced(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlightService.create_manual_flight(
            db=mock_db_session,
            trip=trip,
            flight_number="af123",
            airline="Air France",
            departure_airport="CDG",
            arrival_airport="BCN",
            departure_date=datetime(2026, 5, 1, 10, 0),
            arrival_date=datetime(2026, 5, 1, 12, 0),
            price=Decimal("150.00"),
            currency="EUR",
        )
        assert isinstance(flight, ManualFlight)
        assert flight.flight_number == "AF123"
        # add() called twice: flight + budget_item
        assert mock_db_session.add.call_count == 2

    def test_creates_flight_only_when_no_price(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        ManualFlightService.create_manual_flight(
            db=mock_db_session,
            trip=trip,
            flight_number="LH100",
            price=None,
        )
        assert mock_db_session.add.call_count == 1

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ManualFlightService.create_manual_flight(
                db=mock_db_session, trip=trip, flight_number="AF1"
            )
        assert exc.value.code == "TRIP_COMPLETED"


class TestGetters:
    def test_get_by_trip(self, mock_db_session):
        flights = [ManualFlight(trip_id=uuid.uuid4(), flight_number="AF1")]
        mock_db_session.query.return_value.filter.return_value.all.return_value = flights
        assert (
            ManualFlightService.get_manual_flights_by_trip(mock_db_session, uuid.uuid4()) == flights
        )

    def test_get_by_id_none(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        assert (
            ManualFlightService.get_manual_flight_by_id(mock_db_session, uuid.uuid4(), uuid.uuid4())
            is None
        )


class TestUpdate:
    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            ManualFlightService.update_manual_flight(
                db=mock_db_session, flight_id=uuid.uuid4(), trip=trip, flight_number="X"
            )
        assert exc.value.code == "FLIGHT_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ManualFlightService.update_manual_flight(
                db=mock_db_session, flight_id=uuid.uuid4(), trip=trip
            )
        assert exc.value.code == "TRIP_COMPLETED"

    def test_updates_fields_without_price_change(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlight(
            trip_id=trip.id,
            flight_number="AF1",
            airline="AF",
            departure_airport="CDG",
            arrival_airport="BCN",
            price=Decimal("100"),
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight

        result = ManualFlightService.update_manual_flight(
            db=mock_db_session,
            flight_id=flight.id,
            trip=trip,
            flight_number="lh999",
            airline="LH",
            departure_airport="MUC",
            arrival_airport="ORY",
            departure_date=datetime(2026, 7, 1, 8, 0),
            arrival_date=datetime(2026, 7, 1, 10, 0),
            currency="EUR",
            notes="updated",
            flight_type="INTERNAL",
        )
        assert result.flight_number == "LH999"
        assert result.airline == "LH"
        assert result.departure_airport == "MUC"
        assert result.flight_type == "INTERNAL"
        assert mock_db_session.commit.called

    def test_price_set_updates_linked_budget_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlight(trip_id=trip.id, flight_number="AF1", price=Decimal("100"))
        linked = BudgetItem(trip_id=trip.id, label="Vol", amount=Decimal("100"))

        mock_db_session.query.return_value.filter.return_value.first.return_value = flight

        with patch(
            "src.services.manual_flight_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            ManualFlightService.update_manual_flight(
                db=mock_db_session, flight_id=flight.id, trip=trip, price=Decimal("200")
            )

        assert linked.amount == Decimal("200")
        assert flight.price == Decimal("200")

    def test_price_set_creates_budget_item_when_none(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlight(
            trip_id=trip.id,
            flight_number="AF1",
            price=None,
            departure_date=datetime(2026, 7, 1, 8, 0),
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight

        with patch(
            "src.services.manual_flight_service.BudgetItemService.find_by_source",
            return_value=None,
        ):
            ManualFlightService.update_manual_flight(
                db=mock_db_session, flight_id=flight.id, trip=trip, price=Decimal("150")
            )

        assert flight.price == Decimal("150")
        # A new BudgetItem should have been added
        assert mock_db_session.add.called

    def test_price_none_deletes_linked_budget_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlight(trip_id=trip.id, flight_number="AF1", price=Decimal("100"))
        linked = BudgetItem(trip_id=trip.id, label="Vol", amount=Decimal("100"))
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight

        with patch(
            "src.services.manual_flight_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            ManualFlightService.update_manual_flight(
                db=mock_db_session, flight_id=flight.id, trip=trip, price=None
            )

        mock_db_session.delete.assert_called_once_with(linked)


class TestDelete:
    def test_happy_path_with_linked_budget_item(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        flight = ManualFlight(trip_id=trip.id, flight_number="AF1")
        linked = BudgetItem(trip_id=trip.id, label="Vol", amount=Decimal("100"))
        mock_db_session.query.return_value.filter.return_value.first.return_value = flight

        with patch(
            "src.services.manual_flight_service.BudgetItemService.find_by_source",
            return_value=linked,
        ):
            ManualFlightService.delete_manual_flight(mock_db_session, flight.id, trip)

        # Both linked item and flight deleted
        assert mock_db_session.delete.call_count == 2
        assert mock_db_session.commit.called

    def test_not_found(self, mock_db_session, make_trip):
        trip = make_trip(status="PLANNED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        with pytest.raises(AppError) as exc:
            ManualFlightService.delete_manual_flight(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "FLIGHT_NOT_FOUND"

    def test_blocked_on_completed_trip(self, mock_db_session, make_trip):
        trip = make_trip(status="COMPLETED")
        with pytest.raises(AppError) as exc:
            ManualFlightService.delete_manual_flight(mock_db_session, uuid.uuid4(), trip)
        assert exc.value.code == "TRIP_COMPLETED"
