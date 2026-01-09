"""Unit tests for hotel offers routes."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.hotels.offers.routes import router as hotel_offers_router
from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.models.hotel_offer import HotelOffer
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(hotel_offers_router)


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


class TestGetHotelOffer:
    """Tests for GET /v1/trips/{tripId}/hotels/offers/{offerDbId}."""

    @patch("src.api.hotels.offers.routes.TripsService")
    def test_get_hotel_offer_success(self, mock_trips_service, client, override_get_current_user, override_get_db, mock_db_session):
        """Test successful retrieval of hotel offer."""
        trip_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        
        # Mock Trip exists
        mock_trips_service.get_trip_by_id.return_value = MagicMock()
        
        # Mock Offer exists
        mock_offer = HotelOffer(
            id=offer_id,
            trip_id=trip_id,
            offer_json={"some": "data"}
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = mock_offer
        
        response = client.get(f"/v1/trips/{trip_id}/hotels/offers/{offer_id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(offer_id)
        assert data["offer"] == {"some": "data"}

    @patch("src.api.hotels.offers.routes.TripsService")
    def test_get_hotel_offer_trip_not_found(self, mock_trips_service, client, override_get_current_user, override_get_db):
        """Test when trip is not found."""
        mock_trips_service.get_trip_by_id.return_value = None
        
        trip_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        
        response = client.get(f"/v1/trips/{trip_id}/hotels/offers/{offer_id}")
        
        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Trip not found"

    @patch("src.api.hotels.offers.routes.TripsService")
    def test_get_hotel_offer_not_found(self, mock_trips_service, client, override_get_current_user, override_get_db, mock_db_session):
        """Test when offer is not found."""
        mock_trips_service.get_trip_by_id.return_value = MagicMock()
        
        # Mock Offer not found
        mock_db_session.query.return_value.filter.return_value.first.return_value = None
        
        trip_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        
        response = client.get(f"/v1/trips/{trip_id}/hotels/offers/{offer_id}")
        
        assert response.status_code == 404
        assert response.json()["detail"]["error"] == "Hotel offer not found"
