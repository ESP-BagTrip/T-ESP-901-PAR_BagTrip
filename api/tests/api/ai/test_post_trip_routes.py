"""Route tests for ai/post_trip_routes.py — post-trip suggestion."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.ai.post_trip_routes import router as post_trip_router
from src.api.auth.plan_guard import require_ai_quota, require_premium
from src.config.database import get_db
from src.utils.errors import AppError


@pytest.fixture
def mock_db() -> MagicMock:
    return MagicMock()


@pytest.fixture
def current_user() -> MagicMock:
    user = MagicMock()
    user.id = uuid.uuid4()
    return user


@pytest.fixture
def app(mock_db: MagicMock, current_user: MagicMock) -> FastAPI:
    app = FastAPI()
    app.include_router(post_trip_router)

    app.dependency_overrides[require_ai_quota] = lambda: current_user
    app.dependency_overrides[require_premium] = lambda: current_user
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


_SUGGESTION = {
    "destination": "Kyoto",
    "destinationCountry": "Japan",
    "durationDays": 7,
    "budgetEur": 2500,
    "description": "Ancient temples, bamboo forests and sushi.",
    "highlightsMatch": ["culture", "food"],
    "activities": [
        {
            "title": "Visit Fushimi Inari",
            "description": "Orange gates at dawn",
            "category": "SIGHTSEEING",
            "estimatedCost": 0.0,
        }
    ],
}


class TestSuggestPostTrip:
    def test_success_flat_suggestion(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripAIService.suggest_next_trip",
                return_value={"suggestion": _SUGGESTION},
            ),
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ) as incr,
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 200
        body = response.json()
        assert body["suggestion"]["destination"] == "Kyoto"
        assert body["suggestion"]["durationDays"] == 7
        incr.assert_called_once()

    def test_success_raw_dict(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripAIService.suggest_next_trip",
                return_value=_SUGGESTION,
            ),
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ),
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 200
        assert response.json()["suggestion"]["destination"] == "Kyoto"

    def test_service_error(self, client: TestClient) -> None:
        with patch(
            "src.api.ai.post_trip_routes.PostTripAIService.suggest_next_trip",
            side_effect=AppError("NO_FEEDBACK", 400, "No feedback history"),
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "NO_FEEDBACK"

    def test_increment_not_called_on_error(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripAIService.suggest_next_trip",
                side_effect=AppError("NO_FEEDBACK", 400, "No feedback"),
            ),
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ) as incr,
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 400
        incr.assert_not_called()
