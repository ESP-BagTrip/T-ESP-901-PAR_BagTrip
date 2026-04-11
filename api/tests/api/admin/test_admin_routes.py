"""Tests pour les routes admin."""

from datetime import UTC, datetime
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.admin.routes import router as admin_router
from src.api.auth.middleware import get_current_user
from src.utils.errors import AppError

# Setup test app
app = FastAPI()
app.include_router(admin_router)


# Mock dependencies
@pytest.fixture
def mock_db():
    return MagicMock()


@pytest.fixture
def mock_current_user():
    return MagicMock(id=uuid4(), email="admin@example.com", is_admin=True, plan="ADMIN")


@pytest.fixture
def client(mock_db, mock_current_user):
    # Override dependencies
    from src.api.auth.admin_guard import require_admin
    from src.config.database import get_db

    app.dependency_overrides[get_current_user] = lambda: mock_current_user
    app.dependency_overrides[require_admin] = lambda: mock_current_user
    app.dependency_overrides[get_db] = lambda: mock_db

    with TestClient(app) as c:
        yield c

    # Clean up overrides
    app.dependency_overrides = {}


@pytest.fixture
def mock_admin_service():
    with patch("src.api.admin.routes.AdminService") as mock:
        yield mock


class TestAdminRoutes:
    """Tests pour les routes admin."""

    def test_admin_health(self, client):
        """Test du health check admin."""
        response = client.get("/admin/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok", "message": "Admin routes are working"}

    def test_list_all_users_success(self, client, mock_admin_service):
        """Test listing users successfully."""
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {"id": user_id, "email": "user@example.com", "created_at": now, "updated_at": now}
        ]
        mock_admin_service.get_all_users.return_value = (mock_data, 1, 1)

        response = client.get("/admin/users?page=1&limit=10")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(user_id)
        assert data["total"] == 1
        assert data["page"] == 1
        assert data["limit"] == 10
        assert data["total_pages"] == 1
        mock_admin_service.get_all_users.assert_called_once()

    def test_list_all_users_error(self, client, mock_admin_service):
        """Test listing users with service error."""
        mock_admin_service.get_all_users.side_effect = AppError("DB_ERROR", 500, "Database error")

        response = client.get("/admin/users")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Database error"

    def test_list_all_users_generic_error(self, client, mock_admin_service):
        """Test listing users with generic error."""
        mock_admin_service.get_all_users.side_effect = Exception("Unexpected error")

        response = client.get("/admin/users")

        assert response.status_code == 500
        assert "Failed to fetch users" in response.json()["detail"]["error"]

    def test_list_all_trips_success(self, client, mock_admin_service):
        """Test listing trips successfully."""
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": trip_id,
                "user_id": user_id,
                "user_email": "user@example.com",
                "title": "Trip 1",
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_trips.return_value = (mock_data, 1, 1)

        response = client.get("/admin/trips")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(trip_id)
        mock_admin_service.get_all_trips.assert_called_once()

    def test_list_all_trips_error(self, client, mock_admin_service):
        """Test listing trips with error."""
        mock_admin_service.get_all_trips.side_effect = Exception("Fail")
        response = client.get("/admin/trips")
        assert response.status_code == 500
        assert "Failed to fetch trips" in response.json()["detail"]["error"]

    def test_list_all_travelers_success(self, client, mock_admin_service):
        """Test listing travelers successfully."""
        traveler_id = uuid4()
        trip_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": traveler_id,
                "trip_id": trip_id,
                "user_email": "user@example.com",
                "traveler_type": "ADULT",
                "first_name": "John",
                "last_name": "Doe",
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_travelers.return_value = (mock_data, 1, 1)

        response = client.get("/admin/travelers")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(traveler_id)
        mock_admin_service.get_all_travelers.assert_called_once()

    def test_list_all_travelers_error(self, client, mock_admin_service):
        """Test listing travelers with error."""
        mock_admin_service.get_all_travelers.side_effect = Exception("Fail")
        response = client.get("/admin/travelers")
        assert response.status_code == 500
        assert "Failed to fetch travelers" in response.json()["detail"]["error"]

    def test_list_all_flight_bookings_success(self, client, mock_admin_service):
        """Test listing flight bookings successfully."""
        booking_id = uuid4()
        trip_id = uuid4()
        offer_id = uuid4()
        now = datetime.now(UTC)
        mock_data = [
            {
                "id": booking_id,
                "trip_id": trip_id,
                "user_email": "user@example.com",
                "flight_offer_id": offer_id,
                "created_at": now,
                "updated_at": now,
            }
        ]
        mock_admin_service.get_all_flight_bookings.return_value = (mock_data, 1, 1)

        response = client.get("/admin/flight-bookings")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(booking_id)
        mock_admin_service.get_all_flight_bookings.assert_called_once()

    def test_list_all_flight_bookings_error(self, client, mock_admin_service):
        """Test listing flight bookings with error."""
        mock_admin_service.get_all_flight_bookings.side_effect = Exception("Fail")
        response = client.get("/admin/flight-bookings")
        assert response.status_code == 500
        assert "Failed to fetch flight bookings" in response.json()["detail"]["error"]
