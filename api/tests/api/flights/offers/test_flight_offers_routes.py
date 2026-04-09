"""Unit tests for the flight offers routes."""

from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

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
from src.api.flights.offers.routes import router as flight_offers_router
from src.config.database import get_db
from src.models.flight_offer import FlightOffer
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(flight_offers_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


# Module-level mocks reused across tests
mock_user_id = uuid4()
mock_user = User(id=mock_user_id, email="test@example.com")
mock_db_session = MagicMock()

app.dependency_overrides[get_current_user] = lambda: mock_user
app.dependency_overrides[get_db] = lambda: mock_db_session


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


@pytest.fixture
def trip_access(mock_trip_id):
    """Provide a TripAccess override for the mock trip."""
    mock_trip = MagicMock()
    mock_trip.id = mock_trip_id
    access = TripAccess(trip=mock_trip, role=TripRole.OWNER)
    app.dependency_overrides[get_trip_access] = lambda: access
    app.dependency_overrides[get_trip_owner_access] = lambda: access
    app.dependency_overrides[get_trip_editor_access] = lambda: access
    yield access
    app.dependency_overrides.pop(get_trip_access, None)
    app.dependency_overrides.pop(get_trip_owner_access, None)
    app.dependency_overrides.pop(get_trip_editor_access, None)


class TestGetFlightOffer:

    def test_get_flight_offer_success(self, client, mock_trip_id, mock_offer_id, trip_access):
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

    def test_get_flight_offer_trip_not_found(self, client, mock_trip_id, mock_offer_id):
        """Test when TripAccess raises 404 (trip not found)."""
        # No trip_access override — the real get_trip_access will query the DB and find nothing
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}")

        assert response.status_code == 404

    def test_get_flight_offer_not_found(self, client, mock_trip_id, mock_offer_id, trip_access):
        # Mock DB query returning None for Offer
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "OFFER_NOT_FOUND"


class TestPriceFlightOffer:

    @patch("src.api.flights.offers.routes.FlightOfferPricingService")
    def test_price_flight_offer_success(self, mock_pricing_service, client, mock_trip_id, mock_offer_id, trip_access):
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
        )

    @patch("src.api.flights.offers.routes.FlightOfferPricingService")
    def test_price_flight_offer_error(self, mock_pricing_service, client, mock_trip_id, mock_offer_id, trip_access):
        # Mock FlightOfferPricingService raising AppError
        mock_pricing_service.price_offer = AsyncMock(side_effect=AppError("PRICING_FAILED", 400, "Pricing failed"))

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/offers/{mock_offer_id}/price")

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "PRICING_FAILED"
