"""Unit tests for the aggregated Home route (SMP327-021)."""

import uuid
from datetime import UTC, date, datetime, time
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.schemas import UserResponse
from src.api.home.routes import router as home_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

app = FastAPI()
app.include_router(home_router)


@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture
def mock_db_session():
    return MagicMock()


@pytest.fixture
def override_get_db(mock_db_session):
    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user():
    return User(
        id=uuid.uuid4(),
        email="test@example.com",
        full_name="Test User",
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.fixture
def override_get_current_user(mock_user):
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user_response(mock_user):
    """The enriched UserResponse the service returns (mirrors /auth/me)."""
    return UserResponse(
        id=mock_user.id,
        email=mock_user.email,
        full_name="Test User",
        created_at=mock_user.created_at,
        updated_at=mock_user.updated_at,
        is_profile_completed=True,
        email_verified=True,
        plan="FREE",
        ai_generations_remaining=3,
        plan_expires_at=None,
    )


def _make_trip(status: str) -> MagicMock:
    trip = MagicMock()
    trip.id = uuid.uuid4()
    trip.title = f"{status} trip"
    trip.origin_iata = "CDG"
    trip.destination_iata = "BCN"
    trip.start_date = date(2027, 12, 1)
    trip.end_date = date(2027, 12, 10)
    trip.status = status
    trip.description = None
    trip.destination_name = "Barcelona"
    trip.destination_timezone = None
    trip.nb_travelers = 2
    trip.cover_image_url = None
    trip.budget_target = None
    trip.budget_estimated = None
    trip.budget_actual = None
    trip.origin = "MANUAL"
    trip.date_mode = "EXACT"
    trip.flights_tracking = "TRACKED"
    trip.accommodations_tracking = "TRACKED"
    trip.archived_at = None
    trip.role = None
    trip.completion_percentage = 0
    trip.created_at = datetime.now(UTC)
    trip.updated_at = datetime.now(UTC)
    return trip


def _make_activity(trip_id: uuid.UUID) -> MagicMock:
    act = MagicMock()
    act.id = uuid.uuid4()
    act.trip_id = trip_id
    act.title = "Visit Sagrada Familia"
    act.description = None
    act.date = date(2027, 12, 1)
    act.start_time = time(10, 0)
    act.end_time = None
    act.location = None
    act.category = "SIGHTSEEING"
    act.estimated_cost = 25.0
    act.is_booked = False
    act.is_done = False
    act.validation_status = "MANUAL"
    act.created_at = datetime.now(UTC)
    act.updated_at = datetime.now(UTC)
    return act


class TestGetHome:
    """Tests for GET /v1/home."""

    @patch("src.api.home.routes._enrich_with_completion")
    @patch("src.api.home.routes.HomeService")
    def test_home_with_active_trip(
        self,
        mock_service,
        mock_enrich,
        client,
        override_get_current_user,
        override_get_db,
        mock_user_response,
    ):
        """Active trip present → groups + user + activities + weather populated."""
        ongoing = _make_trip("ONGOING")
        planned = _make_trip("PLANNED")
        completed = _make_trip("COMPLETED")
        activity = _make_activity(ongoing.id)

        mock_service.get_home = AsyncMock(
            return_value={
                "user": mock_user_response,
                "ongoing": [(ongoing, "OWNER")],
                "planned": [(planned, "OWNER")],
                "completed": [(completed, "VIEWER")],
                "active_trip": ongoing,
                "active_trip_activities": [activity],
                "active_trip_weather": {
                    "avg_temp_c": 18.0,
                    "min_temp_c": 12.0,
                    "max_temp_c": 24.0,
                    "description": "Sunny",
                    "rain_probability": 10,
                    "source": "open-meteo",
                },
            }
        )

        response = client.get("/v1/home")

        assert response.status_code == 200
        data = response.json()
        assert len(data["ongoingTrips"]) == 1
        assert data["ongoingTrips"][0]["id"] == str(ongoing.id)
        assert data["ongoingTrips"][0]["role"] == "OWNER"
        assert len(data["plannedTrips"]) == 1
        assert len(data["completedTrips"]) == 1
        assert data["user"]["email"] == "test@example.com"
        assert len(data["activeTripActivities"]) == 1
        assert data["activeTripActivities"][0]["id"] == str(activity.id)
        assert data["activeTripWeather"]["description"] == "Sunny"
        mock_service.get_home.assert_awaited_once()

    @patch("src.api.home.routes._enrich_with_completion")
    @patch("src.api.home.routes.HomeService")
    def test_home_without_active_trip(
        self,
        mock_service,
        mock_enrich,
        client,
        override_get_current_user,
        override_get_db,
        mock_user_response,
    ):
        """No ongoing trip → activeTrip* are empty / None."""
        planned = _make_trip("PLANNED")

        mock_service.get_home = AsyncMock(
            return_value={
                "user": mock_user_response,
                "ongoing": [],
                "planned": [(planned, "OWNER")],
                "completed": [],
                "active_trip": None,
                "active_trip_activities": [],
                "active_trip_weather": None,
            }
        )

        response = client.get("/v1/home")

        assert response.status_code == 200
        data = response.json()
        assert data["ongoingTrips"] == []
        assert len(data["plannedTrips"]) == 1
        assert data["completedTrips"] == []
        assert data["activeTripActivities"] == []
        assert data["activeTripWeather"] is None

    def test_home_requires_auth(self, client, override_get_db):
        """No authenticated user → 401/403 (auth dependency enforced)."""
        response = client.get("/v1/home")
        assert response.status_code in (401, 403)

    @patch("src.api.home.routes._enrich_with_completion")
    @patch("src.api.home.routes.HomeService")
    def test_home_propagates_app_error(
        self,
        mock_service,
        mock_enrich,
        client,
        override_get_current_user,
        override_get_db,
    ):
        """AppError from the service is mapped to its HTTP status."""
        mock_service.get_home = AsyncMock(side_effect=AppError("BOOM", 500, "Something failed"))

        response = client.get("/v1/home")

        assert response.status_code == 500
        assert response.json()["detail"]["error"] == "Something failed"
