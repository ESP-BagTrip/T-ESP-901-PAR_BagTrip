"""Unit tests for the booking routes."""

import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.booking.routes import router as booking_router
from src.config.database import get_db
from src.models.booking import Booking
from src.models.user import User

# Setup the test app
app = FastAPI()
app.include_router(booking_router)


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
        email="test@example.com",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )


@pytest.fixture
def override_get_current_user(mock_user):
    """Override the get_current_user dependency."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}



def create_valid_flight_offer():
    """Create a valid FlightOffer dictionary for testing."""
    return {
        "type": "flight-offer",
        "id": "1",
        "source": "GDS",
        "instantTicketingRequired": False,
        "nonHomogeneous": False,
        "oneWay": False,
        "itineraries": [
            {
                "duration": "PT2H",
                "segments": [
                    {
                        "departure": {"iataCode": "CDG", "at": "2025-12-25T10:00:00"},
                        "arrival": {"iataCode": "LHR", "at": "2025-12-25T12:00:00"},
                        "carrierCode": "BA",
                        "number": "123",
                        "duration": "PT2H",
                        "id": "1",
                        "numberOfStops": 0,
                        "blacklistedInEU": False
                    }
                ]
            }
        ],
        "price": {
            "currency": "EUR",
            "total": "100.00",
            "base": "80.00",
            "grandTotal": "100.00",
            "fees": [{"amount": "0.00", "type": "SUPPLIER"}]
        },
        "pricingOptions": {
            "fareType": ["PUBLISHED"],
            "includedCheckedBagsOnly": True
        },
        "validatingAirlineCodes": ["BA"],
        "travelerPricings": [
            {
                "travelerId": "1",
                "fareOption": "STANDARD",
                "travelerType": "ADULT",
                "price": {"currency": "EUR", "total": "100.00", "base": "80.00"},
                "fareDetailsBySegment": [
                    {
                        "segmentId": "1",
                        "cabin": "ECONOMY",
                        "fareBasis": "Y",
                        "class": "Y",
                        "includedCheckedBags": {"quantity": 1}
                    }
                ]
            }
        ]
    }


@patch("src.api.booking.routes.amadeus_client", new_callable=AsyncMock)
class TestConfirmPrice:
    """Test suite for the confirm_price endpoint."""

    def test_confirm_price_success(self, mock_amadeus_client, client):
        """Test successful price confirmation."""
        # The schema expects data to be a dict where values are lists of FlightOffer
        valid_offer = create_valid_flight_offer()
        mock_amadeus_client.confirm_flight_price.return_value = {
            "data": {
                "flightOffers": [valid_offer]
            }
        }

        payload = {"flightOffer": valid_offer}

        response = client.post("/v1/booking/pricing", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "flightOffers" in data["data"]
        assert len(data["data"]["flightOffers"]) == 1
        assert data["data"]["flightOffers"][0]["id"] == valid_offer["id"]
        assert data["data"]["flightOffers"][0]["price"]["total"] == valid_offer["price"]["total"]
        mock_amadeus_client.confirm_flight_price.assert_called_once()

    def test_confirm_price_error(self, mock_amadeus_client, client):
        """Test error handling during price confirmation."""
        mock_amadeus_client.confirm_flight_price.side_effect = Exception("Amadeus Error")

        payload = {"flightOffer": create_valid_flight_offer()}

        response = client.post("/v1/booking/pricing", json=payload)

        assert response.status_code == 500
        detail = response.json()["detail"]
        assert detail["error"] == "Price confirmation failed"
        assert detail["code"] == "INTERNAL_ERROR"

    def test_confirm_price_debug_logging(self, mock_amadeus_client, client):
        """Test error logging in confirm_price when debug mode is enabled."""
        from src.utils.logger import LogLevel, logger

        original_level = logger.level
        logger.level = LogLevel.DEBUG

        try:
            mock_amadeus_client.confirm_flight_price.side_effect = Exception("Debug Error")
            payload = {"flightOffer": create_valid_flight_offer()}
            response = client.post("/v1/booking/pricing", json=payload)
            assert response.status_code == 500
        finally:
            logger.level = original_level


@patch("src.api.booking.routes.amadeus_client", new_callable=AsyncMock)
class TestCreateBooking:
    """Test suite for the create_booking endpoint."""

    def test_create_booking_success(self, mock_amadeus_client, client, override_get_current_user, override_get_db, mock_db_session):
        """Test successful booking creation."""
        # Mock Amadeus response
        mock_response = MagicMock()
        mock_response.data = {
            "id": "AMADEUS_ORDER_ID",
            "flightOffers": [
                {
                    "price": {"grandTotal": "200.50", "currency": "USD"}
                }
            ]
        }
        mock_amadeus_client.create_flight_order.return_value = mock_response

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()

        mock_db_session.refresh.side_effect = refresh_side_effect

        payload = {
            "flightOffer": create_valid_flight_offer(),
            "travelers": [
                {
                    "id": "1",
                    "dateOfBirth": "2000-01-01",
                    "name": {"firstName": "John", "lastName": "Doe"},
                    "gender": "MALE",
                    "contact": {"emailAddress": "john@example.com", "phones": [{"deviceType": "MOBILE", "countryCallingCode": "1", "number": "1234567890"}]}
                }
            ]
        }

        response = client.post("/v1/booking/create", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["amadeusOrderId"] == "AMADEUS_ORDER_ID"
        assert data["priceTotal"] == 200.50
        assert data["currency"] == "USD"

        # Verify DB interactions
        assert mock_db_session.add.called
        assert mock_db_session.commit.called

    def test_create_booking_no_order_id(self, mock_amadeus_client, client, override_get_current_user, override_get_db, mock_db_session):
        """Test booking creation when Amadeus returns no ID."""
        mock_response = MagicMock()
        mock_response.data = {"flightOffers": []}  # No ID
        mock_amadeus_client.create_flight_order.return_value = mock_response

        payload = {
            "flightOffer": create_valid_flight_offer(),
            "travelers": []
        }

        response = client.post("/v1/booking/create", json=payload)

        assert response.status_code == 502
        detail = response.json()["detail"]
        assert detail["error"] == "No order ID received from Amadeus"
        assert detail["code"] == "UPSTREAM_ERROR"
        assert mock_db_session.rollback.called

    def test_create_booking_amadeus_error(self, mock_amadeus_client, client, override_get_current_user, override_get_db, mock_db_session):
        """Test booking creation when Amadeus call fails."""
        mock_amadeus_client.create_flight_order.side_effect = Exception("Amadeus Down")

        payload = {
            "flightOffer": create_valid_flight_offer(),
            "travelers": []
        }

        response = client.post("/v1/booking/create", json=payload)

        assert response.status_code == 500
        detail = response.json()["detail"]
        assert detail["error"] == "Booking creation failed"
        assert detail["code"] == "INTERNAL_ERROR"
        assert mock_db_session.rollback.called

    def test_create_booking_debug_logging(self, mock_amadeus_client, client, override_get_current_user, override_get_db, mock_db_session):
        """Test error logging when debug mode is enabled."""
        from src.utils.logger import LogLevel, logger

        # Save original level
        original_level = logger.level
        logger.level = LogLevel.DEBUG

        try:
            mock_amadeus_client.create_flight_order.side_effect = Exception("Debug Error")

            payload = {
                "flightOffer": create_valid_flight_offer(),
                "travelers": []
            }

            response = client.post("/v1/booking/create", json=payload)

            assert response.status_code == 500
        finally:
            # Restore level
            logger.level = original_level

    def test_create_booking_missing_price(self, mock_amadeus_client, client, override_get_current_user, override_get_db, mock_db_session):
        """Test booking creation when price info is missing in Amadeus response."""
        mock_response = MagicMock()
        mock_response.data = {
            "id": "ORDER_NO_PRICE",
            "flightOffers": []  # Empty flight offers
        }
        mock_amadeus_client.create_flight_order.return_value = mock_response

        def refresh_side_effect(instance):
            instance.id = uuid.uuid4()
            instance.created_at = datetime.utcnow()

        mock_db_session.refresh.side_effect = refresh_side_effect

        payload = {
            "flightOffer": create_valid_flight_offer(),
            "travelers": [
                {
                    "id": "1",
                    "dateOfBirth": "2000-01-01",
                    "name": {"firstName": "John", "lastName": "Doe"},
                    "gender": "MALE",
                    "contact": {"emailAddress": "john@example.com", "phones": [{"deviceType": "MOBILE", "countryCallingCode": "1", "number": "1234567890"}]}
                }
            ]
        }

        response = client.post("/v1/booking/create", json=payload)

        assert response.status_code == 200
        data = response.json()
        assert data["priceTotal"] == 0.0
        assert data["currency"] == "EUR"


class TestListBookings:
    """Test suite for the list_bookings endpoint."""

    def test_list_bookings_success(self, client, override_get_current_user, override_get_db, mock_db_session, mock_user):
        """Test successful retrieval of user bookings."""
        # Setup mock DB return
        mock_booking = Booking(
            id=uuid.uuid4(),
            user_id=mock_user.id,
            amadeus_order_id="TEST_ORDER",
            status="CONFIRMED",
            price_total=150.0,
            currency="EUR",
            created_at=datetime.utcnow()
        )

        mock_db_session.query.return_value.filter.return_value.order_by.return_value.all.return_value = [mock_booking]

        response = client.get("/v1/booking/list")

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["amadeusOrderId"] == "TEST_ORDER"
        assert data[0]["priceTotal"] == 150.0
