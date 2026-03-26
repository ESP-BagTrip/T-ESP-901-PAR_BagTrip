"""Unit tests for the flight searches routes."""

from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.flights.searches.routes import router as flight_searches_router
from src.models.user import User
from src.utils.errors import AppError
from src.api.auth.middleware import get_current_user
from src.config.database import get_db

# Setup the test app
app = FastAPI()
app.include_router(flight_searches_router)

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
def mock_search_id():
    return uuid4()

@patch("src.api.flights.searches.routes.FlightSearchService")
class TestCreateFlightSearch:

    def test_create_flight_search_success(self, mock_service, client, mock_trip_id):
        # Mock FlightSearchService.create_search
        mock_search = MagicMock()
        mock_search.id = uuid4()
        
        mock_offer = MagicMock()
        mock_offer.id = uuid4()
        mock_offer.grand_total = 100.0
        mock_offer.currency = "EUR"
        mock_offer.offer_json = {
            "itineraries": [
                {"segments": [{"id": "1"}, {"id": "2"}]} # 1 stop
            ]
        }
        
        mock_service.create_search = AsyncMock(return_value=(mock_search, [mock_offer]))

        payload = {
            "originIata": "PAR",
            "destinationIata": "NYC",
            "departureDate": "2025-12-01",
            "adults": 1,
            "currency": "EUR"
        }

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/searches", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["searchId"] == str(mock_search.id)
        assert len(data["offers"]) == 1
        assert data["offers"][0]["id"] == str(mock_offer.id)
        assert data["offers"][0]["summary"]["stops"] == 1
        
        mock_service.create_search.assert_called_once()

    def test_create_flight_search_error(self, mock_service, client, mock_trip_id):
        mock_service.create_search = AsyncMock(side_effect=AppError("SEARCH_FAILED", 400, "Search failed"))

        payload = {
            "originIata": "PAR",
            "destinationIata": "NYC",
            "departureDate": "2025-12-01",
            "adults": 1
        }
        
        response = client.post(f"/v1/trips/{mock_trip_id}/flights/searches", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "SEARCH_FAILED"


@patch("src.api.flights.searches.routes.FlightSearchService")
class TestGetFlightSearch:

    def test_get_flight_search_success(self, mock_service, client, mock_trip_id, mock_search_id):
        # Mock FlightSearchService.get_search_by_id
        mock_search = MagicMock()
        mock_search.id = mock_search_id
        mock_search.origin_iata = "PAR"
        mock_search.destination_iata = "NYC"
        mock_search.departure_date = date(2025, 12, 1)
        mock_search.return_date = None
        mock_search.adults = 1
        
        mock_service.get_search_by_id.return_value = mock_search

        # Mock FlightSearchService.get_offers_by_search
        mock_offer = MagicMock()
        mock_offer.id = uuid4()
        mock_offer.amadeus_offer_id = "1"
        mock_offer.grand_total = 100.0
        mock_offer.base_total = 80.0
        mock_offer.currency = "EUR"
        mock_offer.offer_json = {}
        
        mock_service.get_offers_by_search.return_value = [mock_offer]

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/searches/{mock_search_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["search"]["id"] == str(mock_search_id)
        assert data["search"]["originIata"] == "PAR"
        assert len(data["offers"]) == 1
        assert data["offers"][0]["grandTotal"] == 100.0
        
        mock_service.get_search_by_id.assert_called_once_with(mock_db_session, mock_search_id, mock_trip_id, mock_user_id)
        mock_service.get_offers_by_search.assert_called_once_with(mock_db_session, mock_search_id, mock_trip_id, mock_user_id)

    def test_get_flight_search_not_found(self, mock_service, client, mock_trip_id, mock_search_id):
        mock_service.get_search_by_id.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/searches/{mock_search_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "SEARCH_NOT_FOUND"
