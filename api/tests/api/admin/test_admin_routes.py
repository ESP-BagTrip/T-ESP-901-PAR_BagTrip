"""Tests pour les routes admin."""

from datetime import datetime, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.admin.routes import router as admin_router
from src.api.auth.middleware import get_current_user
from src.utils.errors import AppError

# Setup test app
app = FastAPI()
app.include_router(admin_router)

@app.exception_handler(AppError)
async def app_error_handler(request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code}},
    )

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
        now = datetime.now(timezone.utc)
        mock_data = [{
            "id": user_id,
            "email": "user@example.com",
            "created_at": now,
            "updated_at": now,
            "fullName": "Test User",
            "plan": "FREE"
        }]
        mock_admin_service.get_all_users.return_value = (mock_data, 1, 1)

        response = client.get("/admin/users?page=1&limit=10")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(user_id)
        assert data["total"] == 1

    def test_list_all_users_error(self, client, mock_admin_service):
        """Test listing users with service error."""
        mock_admin_service.get_all_users.side_effect = AppError("DB_ERROR", 500, "Database error")
        response = client.get("/admin/users")
        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Database error"

    def test_list_all_trips_success(self, client, mock_admin_service):
        """Test listing trips successfully."""
        trip_id = uuid4()
        user_id = uuid4()
        now = datetime.now(timezone.utc)
        mock_data = [{
            "id": trip_id,
            "user_id": user_id,
            "user_email": "user@example.com",
            "title": "Trip 1",
            "created_at": now,
            "updated_at": now
        }]
        mock_admin_service.get_all_trips.return_value = (mock_data, 1, 1)

        response = client.get("/admin/trips")

        assert response.status_code == 200
        data = response.json()
        assert data["items"][0]["id"] == str(trip_id)

    def test_update_user_plan_success(self, client, mock_admin_service):
        """Test updating user plan."""
        user_id = uuid4()
        response = client.patch(f"/admin/users/{user_id}/plan", json={"plan": "PREMIUM"})
        assert response.status_code == 200
        args, _ = mock_admin_service.update_user_plan.call_args
        assert args[1] == user_id
        assert args[2] == "PREMIUM"

    def test_dashboard_metrics_success(self, client, mock_admin_service):
        """Test fetching dashboard metrics."""
        mock_admin_service.get_dashboard_metrics.return_value = {
            "totalUsers": 10, "activeUsers": 5, "inactiveUsers": 5,
            "totalTrips": 20, "totalRevenue": 100.0, "totalFeedbacks": 30,
            "pendingFeedbacks": 30, "averageRating": 4.5
        }
        response = client.get("/admin/dashboard/metrics")
        assert response.status_code == 200
        assert response.json()["data"]["totalUsers"] == 10

    def test_export_users_csv_success(self, client, mock_admin_service):
        """Test exporting users CSV."""
        mock_admin_service.export_users_csv.return_value = "id,email\n1,test@example.com"
        response = client.get("/admin/users/export")
        assert response.status_code == 200
        assert response.headers["content-type"] == "text/csv; charset=utf-8"
        assert "id,email" in response.text
