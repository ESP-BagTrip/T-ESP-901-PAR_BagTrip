"""Unit tests for the booking intents routes."""

import uuid
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.booking_intents.routes import router as trips_router
from src.api.booking_intents.book_routes import router as booking_intents_router
from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(trips_router)
app.include_router(booking_intents_router)


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
    trip.user_id = uuid.uuid4()
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
    app.dependency_overrides.pop(get_trip_access, None)
    app.dependency_overrides.pop(get_trip_owner_access, None)


@pytest.fixture
def mock_booking_intent():
    """Create a mock booking intent object."""
    intent = MagicMock()
    intent.id = uuid.uuid4()
    intent.type = "flight"
    intent.status = "CREATED"
    intent.amount = Decimal("100.50")
    intent.currency = "EUR"
    intent.selected_offer_id = uuid.uuid4()
    intent.amadeus_order_id = "ORDER_123"
    intent.amadeus_booking_id = None
    return intent


class TestCreateBookingIntent:
    """Tests for POST /v1/trips/{tripId}/booking-intents."""

    @patch("src.api.booking_intents.routes.BookingIntentsService")
    def test_create_booking_intent_success(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_booking_intent, mock_trip):
        """Test successful booking intent creation."""
        mock_service.create_intent.return_value = mock_booking_intent

        trip_id = mock_trip.id
        flight_offer_id = uuid.uuid4()

        payload = {
            "type": "flight",
            "flightOfferId": str(flight_offer_id)
        }

        response = client.post(f"/v1/trips/{trip_id}/booking-intents", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["id"] == str(mock_booking_intent.id)
        assert data["type"] == "flight"
        assert data["status"] == "CREATED"

        mock_service.create_intent.assert_called_once()

    @patch("src.api.booking_intents.routes.BookingIntentsService")
    def test_create_booking_intent_error(self, mock_service, client, override_get_current_user, override_get_db, override_trip_access, mock_trip):
        """Test creation with service error."""
        mock_service.create_intent.side_effect = AppError("ERROR", 400, "Bad Request")

        trip_id = mock_trip.id
        payload = {"type": "flight"}

        response = client.post(f"/v1/trips/{trip_id}/booking-intents", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Bad Request"


class TestGetBookingIntent:
    """Tests for GET /v1/booking-intents/{intentId}."""

    @patch("src.api.booking_intents.book_routes.BookingIntentsService")
    def test_get_booking_intent_success(self, mock_service, client, override_get_current_user, override_get_db, mock_booking_intent):
        """Test successful retrieval."""
        mock_service.get_intent_by_id.return_value = mock_booking_intent

        intent_id = mock_booking_intent.id

        response = client.get(f"/v1/booking-intents/{intent_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(intent_id)

        mock_service.get_intent_by_id.assert_called_once()

    @patch("src.api.booking_intents.book_routes.BookingIntentsService")
    def test_get_booking_intent_not_found_service_returns_none(self, mock_service, client, override_get_current_user, override_get_db):
        """Test not found when service returns None."""
        mock_service.get_intent_by_id.return_value = None

        intent_id = uuid.uuid4()

        response = client.get(f"/v1/booking-intents/{intent_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Booking intent not found"

    @patch("src.api.booking_intents.book_routes.BookingIntentsService")
    def test_get_booking_intent_error(self, mock_service, client, override_get_current_user, override_get_db):
        """Test retrieval with AppError."""
        mock_service.get_intent_by_id.side_effect = AppError("ERROR", 500, "Internal Error")

        intent_id = uuid.uuid4()

        response = client.get(f"/v1/booking-intents/{intent_id}")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Internal Error"


class TestBookBookingIntent:
    """Tests for POST /v1/booking-intents/{intentId}/book."""

    @patch("src.api.booking_intents.book_routes.BookingOrchestratorService")
    def test_book_flight_success(self, mock_orchestrator, client, override_get_current_user, override_get_db, mock_booking_intent):
        """Test successful flight booking."""
        mock_booking_intent.status = "CONFIRMED"
        mock_orchestrator.book = AsyncMock(return_value=mock_booking_intent)

        intent_id = mock_booking_intent.id
        traveler_ids = [str(uuid.uuid4())]

        payload = {
            "travelerIds": traveler_ids,
            "contacts": [{"email": "test@test.com"}]
        }

        response = client.post(f"/v1/booking-intents/{intent_id}/book", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["bookingIntent"]["status"] == "CONFIRMED"
        assert data["amadeus"]["type"] == "flight"
        assert data["amadeus"]["orderId"] == "ORDER_123"

        mock_orchestrator.book.assert_called_once()

    @patch("src.api.booking_intents.book_routes.BookingOrchestratorService")
    def test_book_error(self, mock_orchestrator, client, override_get_current_user, override_get_db):
        """Test booking with error."""
        mock_orchestrator.book = AsyncMock(side_effect=AppError("ERROR", 400, "Booking failed"))

        intent_id = uuid.uuid4()
        payload = {
            "travelerIds": [],
            "contacts": []
        }

        response = client.post(f"/v1/booking-intents/{intent_id}/book", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Booking failed"

    @patch("src.api.booking_intents.book_routes.BookingOrchestratorService")
    def test_book_unknown_type(self, mock_orchestrator, client, override_get_current_user, override_get_db, mock_booking_intent):
        """Test booking with unknown intent type — route returns flight amadeus shape."""
        mock_booking_intent.type = "unknown"
        mock_booking_intent.status = "CONFIRMED"
        mock_booking_intent.amadeus_order_id = "ORDER_123"
        mock_orchestrator.book = AsyncMock(return_value=mock_booking_intent)

        intent_id = mock_booking_intent.id
        traveler_ids = [str(uuid.uuid4())]

        payload = {
            "travelerIds": traveler_ids,
            "contacts": [{"email": "test@test.com"}]
        }

        response = client.post(f"/v1/booking-intents/{intent_id}/book", json=payload)

        assert response.status_code == 201
        data = response.json()
        # The route always returns flight type amadeus structure
        assert data["amadeus"]["type"] == "flight"
        assert data["amadeus"]["orderId"] == "ORDER_123"
