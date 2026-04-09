"""Unit tests for the travelers routes."""

import uuid
from datetime import UTC, date, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
    get_trip_owner_access,
)
from src.api.travelers.routes import router as travelers_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(travelers_router)


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
    """Create a mock trip."""
    trip = MagicMock()
    trip.id = uuid.uuid4()
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
    app.dependency_overrides[get_trip_editor_access] = lambda: mock_trip_access
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_traveler():
    """Create a mock traveler object."""
    traveler = MagicMock()
    traveler.id = uuid.uuid4()
    traveler.amadeus_traveler_ref = "1"
    traveler.traveler_type = "ADULT"
    traveler.first_name = "John"
    traveler.last_name = "Doe"
    traveler.date_of_birth = date(1990, 1, 1)
    traveler.gender = "MALE"
    traveler.documents = []
    traveler.contacts = {}
    traveler.created_at = datetime.now(UTC)
    traveler.updated_at = datetime.now(UTC)
    return traveler


class TestCreateTraveler:
    """Tests for POST /v1/trips/{tripId}/travelers."""

    @patch("src.api.travelers.routes.TravelersService")
    def test_create_traveler_success(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_traveler, mock_trip):
        """Test successful traveler creation."""
        mock_service.create_traveler.return_value = mock_traveler

        trip_id = mock_trip.id
        payload = {
            "travelerType": "ADULT",
            "firstName": "John",
            "lastName": "Doe",
            "dateOfBirth": "1990-01-01"
        }

        response = client.post(f"/v1/trips/{trip_id}/travelers", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["id"] == str(mock_traveler.id)
        assert data["first_name"] == "John"
        mock_service.create_traveler.assert_called_once()

    @patch("src.api.travelers.routes.TravelersService")
    def test_create_traveler_error(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test creation with AppError."""
        mock_service.create_traveler.side_effect = AppError("ERROR", 400, "Bad Request")

        trip_id = mock_trip.id
        payload = {
            "travelerType": "ADULT",
            "firstName": "John",
            "lastName": "Doe"
        }

        response = client.post(f"/v1/trips/{trip_id}/travelers", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Bad Request"


class TestListTravelers:
    """Tests for GET /v1/trips/{tripId}/travelers."""

    @patch("src.api.travelers.routes.TravelersService")
    def test_list_travelers_success(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_traveler, mock_trip):
        """Test successful traveler listing."""
        mock_service.get_travelers_by_trip.return_value = [mock_traveler]

        trip_id = mock_trip.id

        response = client.get(f"/v1/trips/{trip_id}/travelers")

        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["id"] == str(mock_traveler.id)
        mock_service.get_travelers_by_trip.assert_called_once()

    @patch("src.api.travelers.routes.TravelersService")
    def test_list_travelers_error(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test listing with AppError."""
        mock_service.get_travelers_by_trip.side_effect = AppError("ERROR", 500, "Internal Error")

        trip_id = mock_trip.id

        response = client.get(f"/v1/trips/{trip_id}/travelers")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Internal Error"


class TestUpdateTraveler:
    """Tests for PATCH /v1/trips/{tripId}/travelers/{travelerId}."""

    @patch("src.api.travelers.routes.TravelersService")
    def test_update_traveler_success(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_traveler, mock_trip):
        """Test successful traveler update."""
        mock_service.update_traveler.return_value = mock_traveler

        trip_id = mock_trip.id
        traveler_id = mock_traveler.id
        payload = {
            "firstName": "Johnny"
        }

        response = client.patch(f"/v1/trips/{trip_id}/travelers/{traveler_id}", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(traveler_id)
        mock_service.update_traveler.assert_called_once()

    @patch("src.api.travelers.routes.TravelersService")
    def test_update_traveler_error(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test update with AppError."""
        mock_service.update_traveler.side_effect = AppError("ERROR", 404, "Not Found")

        trip_id = mock_trip.id
        traveler_id = uuid.uuid4()
        payload = {"firstName": "Johnny"}

        response = client.patch(f"/v1/trips/{trip_id}/travelers/{traveler_id}", json=payload)

        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Not Found"


class TestDeleteTraveler:
    """Tests for DELETE /v1/trips/{tripId}/travelers/{travelerId}."""

    @patch("src.api.travelers.routes.TravelersService")
    def test_delete_traveler_success(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test successful traveler deletion."""
        mock_service.delete_traveler.return_value = None

        trip_id = mock_trip.id
        traveler_id = uuid.uuid4()

        response = client.delete(f"/v1/trips/{trip_id}/travelers/{traveler_id}")

        assert response.status_code == 204
        mock_service.delete_traveler.assert_called_once()

    @patch("src.api.travelers.routes.TravelersService")
    def test_delete_traveler_error(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test deletion with AppError."""
        mock_service.delete_traveler.side_effect = AppError("ERROR", 403, "Forbidden")

        trip_id = mock_trip.id
        traveler_id = uuid.uuid4()

        response = client.delete(f"/v1/trips/{trip_id}/travelers/{traveler_id}")

        assert response.status_code == 403
        assert response.json()["detail"]["error"] == "Forbidden"
