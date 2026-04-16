"""Unit tests for the flight searches routes."""

from datetime import date
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
from src.api.flights.searches.routes import router as flight_searches_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(flight_searches_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


# Module-level fixtures reused across tests
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
def mock_search_id():
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


@patch("src.api.flights.searches.routes.FlightSearchService")
class TestCreateFlightSearch:
    def test_create_flight_search_success(self, mock_service, client, mock_trip_id, trip_access):
        # Mock FlightSearchService.create_search
        mock_search = MagicMock()
        mock_search.id = uuid4()
        mock_search.amadeus_response = {
            "data": [{"id": "1", "price": {"grandTotal": "100.00"}}],
            "dictionaries": {"carriers": {"AF": "Air France"}},
        }

        mock_offer = MagicMock()
        mock_offer.id = uuid4()
        mock_offer.grand_total = 100.0
        mock_offer.currency = "EUR"
        mock_offer.offer_json = {
            "itineraries": [
                {"segments": [{"id": "1"}, {"id": "2"}]}  # 1 stop
            ]
        }

        mock_service.create_search = AsyncMock(return_value=(mock_search, [mock_offer]))

        payload = {
            "originIata": "PAR",
            "destinationIata": "NYC",
            "departureDate": "2027-12-01",
            "adults": 1,
            "currency": "EUR",
        }

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/searches", json=payload)

        assert response.status_code == 201
        data = response.json()
        assert data["searchId"] == str(mock_search.id)
        assert len(data["offers"]) == 1
        assert data["offers"][0]["id"] == str(mock_offer.id)
        assert data["offers"][0]["summary"]["stops"] == 1
        # Verify amadeusData and dictionaries are included
        assert data["amadeusData"] is not None
        assert len(data["amadeusData"]) == 1
        assert data["dictionaries"]["carriers"]["AF"] == "Air France"

        mock_service.create_search.assert_called_once()

    def test_create_flight_search_error(self, mock_service, client, mock_trip_id, trip_access):
        mock_service.create_search = AsyncMock(
            side_effect=AppError("SEARCH_FAILED", 400, "Search failed")
        )

        payload = {
            "originIata": "PAR",
            "destinationIata": "NYC",
            "departureDate": "2027-12-01",
            "adults": 1,
        }

        response = client.post(f"/v1/trips/{mock_trip_id}/flights/searches", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "SEARCH_FAILED"


@patch("src.api.flights.searches.routes.FlightSearchService")
class TestGetFlightSearch:
    def test_get_flight_search_success(
        self, mock_service, client, mock_trip_id, mock_search_id, trip_access
    ):
        # Mock FlightSearchService.get_search_by_id
        mock_search = MagicMock()
        mock_search.id = mock_search_id
        mock_search.origin_iata = "PAR"
        mock_search.destination_iata = "NYC"
        mock_search.departure_date = date(2027, 12, 1)
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

        mock_service.get_search_by_id.assert_called_once_with(
            mock_db_session, mock_search_id, mock_trip_id
        )
        mock_service.get_offers_by_search.assert_called_once_with(
            mock_db_session, mock_search_id, mock_trip_id
        )

    def test_get_flight_search_not_found(
        self, mock_service, client, mock_trip_id, mock_search_id, trip_access
    ):
        mock_service.get_search_by_id.return_value = None

        response = client.get(f"/v1/trips/{mock_trip_id}/flights/searches/{mock_search_id}")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "SEARCH_NOT_FOUND"


@patch("src.api.flights.searches.routes.FlightSearchService")
class TestCreateMultiDestSearch:
    def test_multi_dest_success_two_segments(self, mock_service, client, mock_trip_id, trip_access):
        # Build two mock segment results
        results = []
        for _origin, _dest in [("CDG", "NRT"), ("NRT", "BKK")]:
            mock_search = MagicMock()
            mock_search.id = uuid4()
            mock_search.amadeus_response = {
                "data": [{"id": "1", "price": {"grandTotal": "500.00"}}],
                "dictionaries": {"carriers": {"AF": "Air France"}},
            }
            mock_offer = MagicMock()
            mock_offer.id = uuid4()
            mock_offer.grand_total = 500.0
            mock_offer.currency = "EUR"
            mock_offer.offer_json = {"itineraries": [{"segments": [{"id": "1"}]}]}
            results.append((mock_search, [mock_offer]))

        mock_service.create_multi_dest_search = AsyncMock(return_value=results)

        payload = {
            "segments": [
                {"originIata": "CDG", "destinationIata": "NRT", "departureDate": "2027-06-01"},
                {"originIata": "NRT", "destinationIata": "BKK", "departureDate": "2027-06-05"},
            ],
            "adults": 1,
            "currency": "EUR",
        }

        response = client.post(
            f"/v1/trips/{mock_trip_id}/flights/searches/multi",
            json=payload,
        )

        assert response.status_code == 201
        data = response.json()
        assert len(data["segments"]) == 2
        assert data["segments"][0]["amadeusData"] is not None
        assert data["segments"][1]["amadeusData"] is not None

        mock_service.create_multi_dest_search.assert_called_once()

    def test_multi_dest_empty_segments_rejected(
        self, mock_service, client, mock_trip_id, trip_access
    ):
        payload = {
            "segments": [],
            "adults": 1,
        }

        response = client.post(
            f"/v1/trips/{mock_trip_id}/flights/searches/multi",
            json=payload,
        )

        assert response.status_code == 422

    def test_multi_dest_error(self, mock_service, client, mock_trip_id, trip_access):
        mock_service.create_multi_dest_search = AsyncMock(
            side_effect=AppError("SEARCH_FAILED", 400, "Search failed")
        )

        payload = {
            "segments": [
                {"originIata": "CDG", "destinationIata": "NRT", "departureDate": "2027-06-01"},
            ],
            "adults": 1,
        }

        response = client.post(
            f"/v1/trips/{mock_trip_id}/flights/searches/multi",
            json=payload,
        )

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "SEARCH_FAILED"
