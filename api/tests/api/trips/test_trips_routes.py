"""Unit tests for the trips routes."""

import uuid
from datetime import date, datetime, timezone
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.trips.routes import router as trips_router
from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(trips_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_db_session():
    """Mock the database session."""
    session = MagicMock()
    return session


@pytest.fixture
def override_get_db(mock_db_session):
    """Override the get_db dependency."""
    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user():
    """Create a mock user."""
    return User(
        id=uuid.uuid4(),
        email="test@example.com"
    )


@pytest.fixture
def override_get_current_user(mock_user):
    """Override the get_current_user dependency."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_trip():
    """Create a mock trip object."""
    trip = MagicMock()
    trip.id = uuid.uuid4()
    trip.title = "Paris Trip"
    trip.origin_iata = "NYC"
    trip.destination_iata = "PAR"
    trip.start_date = date(2027, 12, 1)
    trip.end_date = date(2027, 12, 10)
    trip.status = "PLANNED"
    trip.description = None
    trip.destination_name = "Paris"
    trip.nb_travelers = 1
    trip.cover_image_url = None
    trip.budget_total = None
    trip.origin = None
    trip.date_mode = "EXACT"
    trip.archived_at = None
    trip.role = None
    trip.created_at = datetime.now(timezone.utc)
    trip.updated_at = datetime.now(timezone.utc)
    return trip


@pytest.fixture
def mock_trip_access(mock_trip):
    """Return a TripAccess for the mock trip."""
    return TripAccess(trip=mock_trip, role=TripRole.OWNER)


@pytest.fixture
def override_trip_access(mock_trip_access):
    """Override both get_trip_access and get_trip_owner_access."""
    app.dependency_overrides[get_trip_access] = lambda: mock_trip_access
    app.dependency_overrides[get_trip_owner_access] = lambda: mock_trip_access
    yield
    app.dependency_overrides = {}


class TestCreateTrip:
    """Tests for POST /v1/trips."""

    @patch("src.api.trips.routes.TripsService")
    def test_create_trip_success(self, mock_service, client, override_get_current_user, override_get_db, mock_trip):
        """Test successful trip creation."""
        mock_service.create_trip.return_value = mock_trip

        payload = {
            "title": "Paris Trip",
            "originIata": "NYC",
            "destinationIata": "PAR",
            "startDate": "2027-12-01",
            "endDate": "2027-12-10"
        }

        response = client.post("/v1/trips", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["id"] == str(mock_trip.id)
        assert data["title"] == "Paris Trip"
        mock_service.create_trip.assert_called_once()

    @patch("src.api.trips.routes.TripsService")
    def test_create_trip_error(self, mock_service, client, override_get_current_user, override_get_db):
        """Test creation with AppError."""
        mock_service.create_trip.side_effect = AppError("ERROR", 400, "Bad Request")

        payload = {
            "title": "Error Trip",
            "destinationName": "Paris"
        }

        response = client.post("/v1/trips", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Bad Request"


class TestListTrips:
    """Tests for GET /v1/trips."""

    @patch("src.api.trips.routes.TripsService")
    def test_list_trips_success(self, mock_service, client, override_get_current_user, override_get_db, mock_trip):
        """Test successful trip listing."""
        mock_service.get_trips_by_user_paginated.return_value = (
            [(mock_trip, "OWNER")],
            1,
            1,
        )

        response = client.get("/v1/trips")

        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["id"] == str(mock_trip.id)
        mock_service.get_trips_by_user_paginated.assert_called_once()

    @patch("src.api.trips.routes.TripsService")
    def test_list_trips_error(self, mock_service, client, override_get_current_user, override_get_db):
        """Test listing with AppError."""
        mock_service.get_trips_by_user_paginated.side_effect = AppError("ERROR", 500, "Internal Error")

        response = client.get("/v1/trips")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Internal Error"


class TestGetTrip:
    """Tests for GET /v1/trips/{tripId}."""

    @patch("src.api.trips.routes.TripsService")
    def test_get_trip_success(self, mock_service, client, override_get_current_user, override_get_db, mock_db_session, mock_trip, override_trip_access):
        """Test successful retrieval of trip details."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        trip_id = mock_trip.id
        response = client.get(f"/v1/trips/{trip_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["trip"]["id"] == str(trip_id)
        assert data["flightOrder"] is None

    @patch("src.api.trips.routes.TripsService")
    def test_get_trip_with_orders_success(self, mock_service, client, override_get_current_user, override_get_db, mock_db_session, mock_trip, override_trip_access):
        """Test retrieval of trip with an associated flight order."""
        flight_order = MagicMock()
        flight_order.id = uuid.uuid4()
        flight_order.amadeus_flight_order_id = "FLIGHT123"
        flight_order.status = "CONFIRMED"

        mock_db_session.query.return_value.filter.return_value.first.return_value = flight_order

        trip_id = mock_trip.id
        response = client.get(f"/v1/trips/{trip_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["flightOrder"]["amadeusFlightOrderId"] == "FLIGHT123"

    def test_get_trip_not_found(self, client, override_get_current_user, override_get_db, mock_db_session):
        """Test when trip is not found — TripAccess returns 404."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        trip_id = uuid.uuid4()
        response = client.get(f"/v1/trips/{trip_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Trip not found"

    def test_get_trip_error(self, client, override_get_current_user, override_get_db, mock_db_session):
        """Test retrieval when trip lookup fails — TripAccess raises 404."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        trip_id = uuid.uuid4()
        response = client.get(f"/v1/trips/{trip_id}")

        assert response.status_code == 404


class TestUpdateTrip:
    """Tests for PATCH /v1/trips/{tripId}."""

    @patch("src.api.trips.routes.TripsService")
    def test_update_trip_success(self, mock_service, client, override_get_current_user, override_get_db, mock_trip, override_trip_access):
        """Test successful trip update."""
        mock_service.update_trip.return_value = mock_trip

        trip_id = mock_trip.id
        payload = {"title": "Updated Trip"}

        response = client.patch(f"/v1/trips/{trip_id}", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(trip_id)
        mock_service.update_trip.assert_called_once()

    @patch("src.api.trips.routes.TripsService")
    def test_update_trip_error(self, mock_service, client, override_get_current_user, override_get_db, mock_trip, override_trip_access):
        """Test update with AppError."""
        mock_service.update_trip.side_effect = AppError("ERROR", 400, "Update failed")

        trip_id = mock_trip.id
        payload = {"title": "Fail Trip"}

        response = client.patch(f"/v1/trips/{trip_id}", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Update failed"


class TestDeleteTrip:
    """Tests for DELETE /v1/trips/{tripId}."""

    @patch("src.api.trips.routes.TripsService")
    def test_delete_trip_success(self, mock_service, client, override_get_current_user, override_get_db, mock_trip, override_trip_access):
        """Test successful trip deletion."""
        mock_service.delete_trip.return_value = None

        trip_id = mock_trip.id
        response = client.delete(f"/v1/trips/{trip_id}")

        assert response.status_code == 204
        mock_service.delete_trip.assert_called_once()

    @patch("src.api.trips.routes.TripsService")
    def test_delete_trip_error(self, mock_service, client, override_get_current_user, override_get_db, mock_trip, override_trip_access):
        """Test deletion with AppError."""
        mock_service.delete_trip.side_effect = AppError("ERROR", 403, "Forbidden")

        trip_id = mock_trip.id
        response = client.delete(f"/v1/trips/{trip_id}")

        assert response.status_code == 403
        assert response.json()["detail"]["error"] == "Forbidden"
