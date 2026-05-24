"""Unit tests for the accommodations routes."""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.accommodations.routes import router as accommodations_router
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
    get_trip_owner_access,
)
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(accommodations_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


# Module-level mocks
mock_user_id = uuid.uuid4()
mock_user = User(id=mock_user_id, email="test@example.com")
mock_db_session = MagicMock()

app.dependency_overrides[get_current_user] = lambda: mock_user
app.dependency_overrides[get_db] = lambda: mock_db_session
app.dependency_overrides[require_ai_quota] = lambda: mock_user


@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_trip_id():
    return uuid.uuid4()


@pytest.fixture
def trip_access(mock_trip_id):
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


class TestSuggestAccommodations:
    """Tests for POST /v1/trips/{tripId}/accommodations/suggest."""

    @patch("src.api.accommodations.routes.AccommodationsService")
    @patch("src.api.accommodations.routes.PlanService")
    def test_suggest_accommodations_success(
        self, mock_plan_service, mock_service, client, mock_trip_id, trip_access
    ):
        """Test successful AI accommodation suggestions."""
        suggestions = [
            {
                "type": "HOTEL",
                "name": "Grand Hotel Paris",
                "neighborhood": "Le Marais",
                "priceRange": "120-180",
                "currency": "EUR",
                "reason": "Central location, great reviews",
                "cityCode": "PAR",
            },
            {
                "type": "AIRBNB",
                "name": "Cozy Montmartre Flat",
                "neighborhood": "Montmartre",
                "priceRange": "80-110",
                "currency": "EUR",
                "reason": "Charming neighborhood, budget-friendly",
                "cityCode": "PAR",
            },
        ]
        mock_service.suggest_accommodations = AsyncMock(return_value=suggestions)

        response = client.post(f"/v1/trips/{mock_trip_id}/accommodations/suggest")

        assert response.status_code == 200
        data = response.json()
        assert "accommodations" in data
        assert len(data["accommodations"]) == 2
        assert data["accommodations"][0]["type"] == "HOTEL"
        assert data["accommodations"][0]["name"] == "Grand Hotel Paris"
        assert data["accommodations"][1]["type"] == "AIRBNB"

        mock_service.suggest_accommodations.assert_called_once()
        mock_plan_service.increment_ai_generation.assert_called_once()

    @patch("src.api.accommodations.routes.AccommodationsService")
    @patch("src.api.accommodations.routes.PlanService")
    def test_suggest_accommodations_empty_result(
        self, mock_plan_service, mock_service, client, mock_trip_id, trip_access
    ):
        """Test LLM returns empty suggestions (graceful degradation)."""
        mock_service.suggest_accommodations = AsyncMock(return_value=[])

        response = client.post(f"/v1/trips/{mock_trip_id}/accommodations/suggest")

        assert response.status_code == 200
        data = response.json()
        assert data["accommodations"] == []
        mock_plan_service.increment_ai_generation.assert_called_once()

    @patch("src.api.accommodations.routes.AccommodationsService")
    def test_suggest_accommodations_service_error(
        self, mock_service, client, mock_trip_id, trip_access
    ):
        """Test AppError from service layer."""
        mock_service.suggest_accommodations = AsyncMock(
            side_effect=AppError("LLM_ERROR", 500, "LLM service unavailable")
        )

        response = client.post(f"/v1/trips/{mock_trip_id}/accommodations/suggest")

        assert response.status_code == 500
        assert response.json()["detail"]["code"] == "LLM_ERROR"

    def test_suggest_accommodations_quota_exceeded(self, client, mock_trip_id, trip_access):
        """Test 402 when AI quota is exceeded."""

        # Override require_ai_quota to raise quota error
        def _quota_exceeded():
            raise AppError("AI_QUOTA_EXCEEDED", 402, "AI generation quota exceeded")

        app.dependency_overrides[require_ai_quota] = _quota_exceeded

        response = client.post(f"/v1/trips/{mock_trip_id}/accommodations/suggest")

        assert response.status_code == 402
        assert response.json()["detail"]["code"] == "AI_QUOTA_EXCEEDED"

        # Restore default
        app.dependency_overrides[require_ai_quota] = lambda: mock_user

    def test_suggest_accommodations_viewer_denied(self, client, mock_trip_id):
        """Test that viewers cannot access suggest endpoint (editor+ only)."""

        def _deny():
            raise AppError("FORBIDDEN", 403, "Editor access required")

        app.dependency_overrides[get_trip_editor_access] = _deny

        response = client.post(f"/v1/trips/{mock_trip_id}/accommodations/suggest")

        assert response.status_code == 403

        # Cleanup
        app.dependency_overrides.pop(get_trip_editor_access, None)
