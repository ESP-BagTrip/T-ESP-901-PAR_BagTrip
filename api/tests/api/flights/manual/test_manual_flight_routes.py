"""Unit tests for the manual flight routes — focusing on PATCH endpoint."""

from datetime import datetime
from decimal import Decimal
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
    get_trip_owner_access,
)
from src.api.flights.manual.routes import router as manual_flights_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(manual_flights_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code}},
    )


mock_user_id = uuid4()
mock_user = User(id=mock_user_id, email="test@example.com")
mock_db_session = MagicMock()

app.dependency_overrides[get_db] = lambda: mock_db_session


@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_trip_id():
    return uuid4()


@pytest.fixture
def mock_flight_id():
    return uuid4()


@pytest.fixture
def trip_access(mock_trip_id):
    mock_trip = MagicMock()
    mock_trip.id = mock_trip_id
    mock_trip.status = "PLANNED"
    access = TripAccess(trip=mock_trip, role=TripRole.OWNER)
    app.dependency_overrides[get_trip_access] = lambda: access
    app.dependency_overrides[get_trip_owner_access] = lambda: access
    app.dependency_overrides[get_trip_editor_access] = lambda: access
    yield access
    app.dependency_overrides.pop(get_trip_access, None)
    app.dependency_overrides.pop(get_trip_owner_access, None)
    app.dependency_overrides.pop(get_trip_editor_access, None)


def _make_mock_flight(flight_id, trip_id):
    flight = MagicMock()
    flight.id = flight_id
    flight.trip_id = trip_id
    flight.flight_number = "AF123"
    flight.airline = "Air France"
    flight.departure_airport = "CDG"
    flight.arrival_airport = "JFK"
    flight.departure_date = datetime(2027, 6, 1, 10, 0)
    flight.arrival_date = datetime(2027, 6, 1, 18, 0)
    flight.price = Decimal("350.00")
    flight.currency = "EUR"
    flight.notes = None
    flight.flight_type = "MAIN"
    flight.validation_status = "MANUAL"
    flight.created_at = datetime(2027, 1, 1)
    flight.updated_at = datetime(2027, 1, 1)
    return flight


@patch("src.api.flights.manual.routes.ManualFlightService")
class TestUpdateManualFlight:
    def test_patch_success(self, mock_service, client, mock_trip_id, mock_flight_id, trip_access):
        mock_flight = _make_mock_flight(mock_flight_id, mock_trip_id)
        mock_flight.airline = "Air France Updated"
        mock_service.update_manual_flight.return_value = mock_flight

        payload = {"airline": "Air France Updated"}
        response = client.patch(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
            json=payload,
        )

        assert response.status_code == 200
        data = response.json()
        assert data["airline"] == "Air France Updated"
        assert data["flight_number"] == "AF123"

        mock_service.update_manual_flight.assert_called_once()
        call_kwargs = mock_service.update_manual_flight.call_args
        assert call_kwargs.kwargs.get("airline") == "Air France Updated"

    def test_patch_partial_update(
        self, mock_service, client, mock_trip_id, mock_flight_id, trip_access
    ):
        mock_flight = _make_mock_flight(mock_flight_id, mock_trip_id)
        mock_flight.price = Decimal("500.00")
        mock_service.update_manual_flight.return_value = mock_flight

        payload = {"price": 500.00}
        response = client.patch(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
            json=payload,
        )

        assert response.status_code == 200
        call_kwargs = mock_service.update_manual_flight.call_args.kwargs
        assert "price" in call_kwargs
        # Only price should be in kwargs, not airline or other fields
        assert "airline" not in call_kwargs

    def test_patch_flight_not_found(
        self, mock_service, client, mock_trip_id, mock_flight_id, trip_access
    ):
        mock_service.update_manual_flight.side_effect = AppError(
            "FLIGHT_NOT_FOUND", 404, "Manual flight not found"
        )

        payload = {"airline": "Test"}
        response = client.patch(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
            json=payload,
        )

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "FLIGHT_NOT_FOUND"

    def test_patch_trip_completed(
        self, mock_service, client, mock_trip_id, mock_flight_id, trip_access
    ):
        mock_service.update_manual_flight.side_effect = AppError(
            "TRIP_COMPLETED", 403, "Cannot modify flights on a completed trip."
        )

        payload = {"airline": "Test"}
        response = client.patch(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
            json=payload,
        )

        assert response.status_code == 403
        assert response.json()["detail"]["code"] == "TRIP_COMPLETED"

    def test_patch_empty_body_accepted(
        self, mock_service, client, mock_trip_id, mock_flight_id, trip_access
    ):
        mock_flight = _make_mock_flight(mock_flight_id, mock_trip_id)
        mock_service.update_manual_flight.return_value = mock_flight

        response = client.patch(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
            json={},
        )

        assert response.status_code == 200
        call_kwargs = mock_service.update_manual_flight.call_args.kwargs
        # No field-specific kwargs, only db, flight_id, trip
        assert "airline" not in call_kwargs
        assert "price" not in call_kwargs


@patch("src.api.flights.manual.routes.ManualFlightService")
class TestCreateManualFlight:
    def test_create_success(self, mock_service, client, mock_trip_id, mock_flight_id, trip_access):
        mock_flight = _make_mock_flight(mock_flight_id, mock_trip_id)
        mock_service.create_manual_flight.return_value = mock_flight

        payload = {
            "flightNumber": "AF123",
            "airline": "Air France",
            "departureAirport": "CDG",
            "arrivalAirport": "JFK",
        }
        response = client.post(
            f"/v1/trips/{mock_trip_id}/flights/manual",
            json=payload,
        )

        assert response.status_code == 201
        data = response.json()
        assert data["flight_number"] == "AF123"

    def test_create_missing_flight_number(self, mock_service, client, mock_trip_id, trip_access):
        response = client.post(
            f"/v1/trips/{mock_trip_id}/flights/manual",
            json={"airline": "Air France"},
        )

        assert response.status_code == 422


@patch("src.api.flights.manual.routes.ManualFlightService")
class TestDeleteManualFlight:
    def test_delete_success(self, mock_service, client, mock_trip_id, mock_flight_id, trip_access):
        mock_service.delete_manual_flight.return_value = None

        response = client.delete(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
        )

        assert response.status_code == 204
        mock_service.delete_manual_flight.assert_called_once()

    def test_delete_not_found(
        self, mock_service, client, mock_trip_id, mock_flight_id, trip_access
    ):
        mock_service.delete_manual_flight.side_effect = AppError(
            "FLIGHT_NOT_FOUND", 404, "Manual flight not found"
        )

        response = client.delete(
            f"/v1/trips/{mock_trip_id}/flights/manual/{mock_flight_id}",
        )

        assert response.status_code == 404
