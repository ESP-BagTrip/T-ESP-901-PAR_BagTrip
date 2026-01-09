"""Unit tests for hotel searches routes."""

import uuid
from datetime import date, datetime
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.hotels.searches.routes import router as hotel_searches_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.models.hotel_search import HotelSearch
from src.models.hotel_offer import HotelOffer
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(hotel_searches_router)


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


class TestCreateHotelSearch:
    """Tests for POST /v1/trips/{tripId}/hotels/searches."""

    @patch("src.api.hotels.searches.routes.HotelSearchService")
    def test_create_hotel_search_success(self, mock_service, client, override_get_current_user, override_get_db):
        """Test successful hotel search creation."""
        search_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        
        mock_search = HotelSearch(id=search_id)
        mock_offer = HotelOffer(
            id=offer_id,
            hotel_id="HOTEL1",
            offer_id="OFFER1",
            total_price=Decimal("150.00"),
            currency="EUR"
        )
        
        mock_service.create_search = AsyncMock(return_value=(mock_search, [mock_offer]))
        
        trip_id = uuid.uuid4()
        payload = {
            "cityCode": "PAR",
            "checkIn": "2025-12-01",
            "checkOut": "2025-12-05",
            "adults": 2,
            "roomQty": 1
        }
        
        response = client.post(f"/v1/trips/{trip_id}/hotels/searches", json=payload)
        
        assert response.status_code == 201
        data = response.json()
        assert data["searchId"] == str(search_id)
        assert len(data["offers"]) == 1
        assert data["offers"][0]["id"] == str(offer_id)
        assert data["offers"][0]["totalPrice"] == 150.0
        
        mock_service.create_search.assert_called_once()

    @patch("src.api.hotels.searches.routes.HotelSearchService")
    def test_create_hotel_search_error(self, mock_service, client, override_get_current_user, override_get_db):
        """Test creation with service error."""
        mock_service.create_search = AsyncMock(side_effect=AppError("AMADEUS_ERROR", 500, "Amadeus error"))
        
        trip_id = uuid.uuid4()
        payload = {
            "cityCode": "PAR",
            "checkIn": "2025-12-01",
            "checkOut": "2025-12-05",
            "adults": 2,
            "roomQty": 1
        }
        
        response = client.post(f"/v1/trips/{trip_id}/hotels/searches", json=payload)
        
        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Amadeus error"


class TestGetHotelSearch:
    """Tests for GET /v1/trips/{tripId}/hotels/searches/{searchId}."""

    @patch("src.api.hotels.searches.routes.HotelSearchService")
    def test_get_hotel_search_success(self, mock_service, client, override_get_current_user, override_get_db):
        """Test successful retrieval of hotel search."""
        search_id = uuid.uuid4()
        mock_search = HotelSearch(
            id=search_id,
            city_code="PAR",
            latitude=Decimal("48.85"),
            longitude=Decimal("2.35"),
            check_in=date(2025, 12, 1),
            check_out=date(2025, 12, 5),
            adults=2,
            room_qty=1
        )
        
        mock_offer = HotelOffer(
            id=uuid.uuid4(),
            hotel_id="HOTEL1",
            offer_id="OFFER1",
            chain_code="CH",
            room_type="Double",
            currency="EUR",
            total_price=Decimal("150.00"),
            offer_json={"raw": "data"}
        )
        
        mock_service.get_search_by_id.return_value = mock_search
        mock_service.get_offers_by_search.return_value = [mock_offer]
        
        trip_id = uuid.uuid4()
        
        response = client.get(f"/v1/trips/{trip_id}/hotels/searches/{search_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["search"]["id"] == str(search_id)
        assert data["search"]["cityCode"] == "PAR"
        assert len(data["offers"]) == 1
        assert data["offers"][0]["hotelId"] == "HOTEL1"

    @patch("src.api.hotels.searches.routes.HotelSearchService")
    def test_get_hotel_search_not_found(self, mock_service, client, override_get_current_user, override_get_db):
        """Test when search is not found."""
        mock_service.get_search_by_id.return_value = None
        
        trip_id = uuid.uuid4()
        search_id = uuid.uuid4()
        
        response = client.get(f"/v1/trips/{trip_id}/hotels/searches/{search_id}")
        
        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Hotel search not found"
