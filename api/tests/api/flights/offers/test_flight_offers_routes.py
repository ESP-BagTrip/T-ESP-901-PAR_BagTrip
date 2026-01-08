"""Unit tests for the flight offers routes."""

from unittest.mock import MagicMock, patch, AsyncMock
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.flights.offers.routes import router as flight_offers_router
from src.models.user import User
from src.models.flight_offer import FlightOffer
from src.utils.errors import AppError
from src.api.auth.middleware import get_current_user
from src.config.database import get_db

# Setup the test app
app = FastAPI()
app.include_router(flight_offers_router)

# Mock user
mock_user_id = uuid4()
mock_user = User(id=mock_user_id, email="test@example.com")

def override_get_current_user():
    return mock_user

# Mock DB Session
mock_db_session = MagicMock()

def override_get_db():
    return mock_db_session

app.dependency_overrides[get_current_user] = override_get_current_user
app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client

@pytest.fixture
def mock_trip_id():
    return uuid4()

@pytest.fixture
def mock_offer_id():
    return uuid4()

@patch("src.api.flights.offers.routes.TripsService")
class TestGetFlightOffer:
    
    def test_get_flight_offer_success(self, mock_trips_service, client, mock_trip_id, mock_offer_id):
        # Mock TripsService
        mock_trip = MagicMock()
        mock_trips_service.get_trip_by_id.return_value = mock_trip

        # Mock DB query for FlightOffer
        mock_offer = FlightOffer(
            id=mock_offer_id,
            trip_id=mock_trip_id,
            offer_json={"price": "100.00", "currency": "EUR"},
            priced_offer_json=None
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_offer

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(mock_offer_id)
        assert data["offer"]["price"] == "100.00"
        
        mock_trips_service.get_trip_by_id.assert_called_with(mock_db_session, mock_trip_id, mock_user_id)

    def test_get_flight_offer_trip_not_found(self, mock_trips_service, client, mock_trip_id, mock_offer_id):
        # Mock TripsService returning None
        mock_trips_service.get_trip_by_id.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "TRIP_NOT_FOUND"

    def test_get_flight_offer_not_found(self, mock_trips_service, client, mock_trip_id, mock_offer_id):
        # Mock TripsService success
        mock_trips_service.get_trip_by_id.return_value = MagicMock()

        # Mock DB query returning None for Offer
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "OFFER_NOT_FOUND"


@patch("src.api.flights.offers.routes.FlightOfferPricingService")
class TestPriceFlightOffer:

    def test_price_flight_offer_success(self, mock_pricing_service, client, mock_trip_id, mock_offer_id):
        # Mock FlightOfferPricingService.price_offer (Async)
        mock_priced_offer = MagicMock()
        mock_priced_offer.id = mock_offer_id
        mock_priced_offer.priced_offer_json = {"price": "120.00", "currency": "EUR"}
        
        mock_pricing_service.price_offer = AsyncMock(return_value=mock_priced_offer)

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}/price")

        assert response.status_code == 200
        data = response.json()
        assert data["offerId"] == str(mock_offer_id)
        assert data["pricedOffer"]["price"] == "120.00"
        
        mock_pricing_service.price_offer.assert_called_once_with(
            db=mock_db_session,
            offer_id=mock_offer_id,
            trip_id=mock_trip_id,
            user_id=mock_user_id
        )

    def test_price_flight_offer_error(self, mock_pricing_service, client, mock_trip_id, mock_offer_id):
        # Mock FlightOfferPricingService raising AppError
        mock_pricing_service.price_offer = AsyncMock(side_effect=AppError("PRICING_FAILED", 400, "Pricing failed"))

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}/price")

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "PRICING_FAILED"
