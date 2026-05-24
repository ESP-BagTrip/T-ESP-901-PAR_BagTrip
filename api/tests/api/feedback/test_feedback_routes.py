"""Route tests for feedback/routes.py — create/list feedback."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access
from src.api.feedback.routes import router as feedback_router
from src.config.database import get_db
from src.utils.errors import AppError


@pytest.fixture
def mock_db() -> MagicMock:
    return MagicMock()


@pytest.fixture
def trip_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def current_user() -> MagicMock:
    user = MagicMock()
    user.id = uuid.uuid4()
    return user


@pytest.fixture
def app(mock_db: MagicMock, trip_id: uuid.UUID, current_user: MagicMock) -> FastAPI:
    app = FastAPI()
    app.include_router(feedback_router)

    trip = MagicMock()
    trip.id = trip_id

    app.dependency_overrides[get_current_user] = lambda: current_user
    app.dependency_overrides[get_trip_access] = lambda: TripAccess(trip=trip, role=TripRole.OWNER)
    app.dependency_overrides[get_db] = lambda: mock_db

    @app.exception_handler(AppError)
    async def _handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": {"error": exc.message, "code": exc.code}},
        )

    return app


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


def _make_feedback(**overrides):
    fb = MagicMock()
    fb.id = overrides.get("id", uuid.uuid4())
    fb.trip_id = overrides.get("trip_id", uuid.uuid4())
    fb.user_id = overrides.get("user_id", uuid.uuid4())
    fb.overall_rating = overrides.get("overall_rating", 5)
    fb.highlights = overrides.get("highlights", "Great trip")
    fb.lowlights = overrides.get("lowlights")
    fb.would_recommend = overrides.get("would_recommend", True)
    fb.ai_experience_rating = overrides.get("ai_experience_rating", 4)
    fb.created_at = overrides.get("created_at", datetime.now(UTC))
    return fb


class TestCreateFeedback:
    def test_success(self, client: TestClient, trip_id: uuid.UUID) -> None:
        fb = _make_feedback(trip_id=trip_id)
        with patch(
            "src.api.feedback.routes.FeedbackService.create_feedback",
            return_value=fb,
        ) as mocked:
            response = client.post(
                f"/v1/trips/{trip_id}/feedback",
                json={
                    "overallRating": 5,
                    "highlights": "Great trip",
                    "wouldRecommend": True,
                    "aiExperienceRating": 4,
                },
            )

        assert response.status_code == 201
        body = response.json()
        assert body["overall_rating"] == 5
        assert body["would_recommend"] is True
        mocked.assert_called_once()

    def test_trip_not_completed(self, client: TestClient, trip_id: uuid.UUID) -> None:
        with patch(
            "src.api.feedback.routes.FeedbackService.create_feedback",
            side_effect=AppError("TRIP_NOT_COMPLETED", 400, "Not completed"),
        ):
            response = client.post(
                f"/v1/trips/{trip_id}/feedback",
                json={"overallRating": 5, "wouldRecommend": True},
            )
        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "TRIP_NOT_COMPLETED"

    def test_invalid_rating_returns_422(self, client: TestClient, trip_id: uuid.UUID) -> None:
        response = client.post(
            f"/v1/trips/{trip_id}/feedback",
            json={"overallRating": 10, "wouldRecommend": True},
        )
        assert response.status_code == 422


class TestListFeedbacks:
    def test_success(self, client: TestClient, trip_id: uuid.UUID) -> None:
        items = [_make_feedback(trip_id=trip_id) for _ in range(2)]
        with patch(
            "src.api.feedback.routes.FeedbackService.get_feedbacks_by_trip",
            return_value=items,
        ) as mocked:
            response = client.get(f"/v1/trips/{trip_id}/feedback")
        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 2
        mocked.assert_called_once()

    def test_empty_list(self, client: TestClient, trip_id: uuid.UUID) -> None:
        with patch(
            "src.api.feedback.routes.FeedbackService.get_feedbacks_by_trip",
            return_value=[],
        ):
            response = client.get(f"/v1/trips/{trip_id}/feedback")
        assert response.status_code == 200
        assert response.json() == {"items": []}

    def test_service_error(self, client: TestClient, trip_id: uuid.UUID) -> None:
        with patch(
            "src.api.feedback.routes.FeedbackService.get_feedbacks_by_trip",
            side_effect=AppError("DB_ERROR", 500, "DB down"),
        ):
            response = client.get(f"/v1/trips/{trip_id}/feedback")
        assert response.status_code == 500
