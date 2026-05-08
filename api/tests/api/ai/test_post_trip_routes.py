"""Route tests for ai/post_trip_routes.py — post-trip suggestion."""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.ai.post_trip_routes import router as post_trip_router
from src.api.auth.plan_guard import require_ai_quota, require_premium
from src.config.database import get_db
from src.services.post_trip_suggester import PostTripSuggestionResult
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


def _suggestion_result() -> PostTripSuggestionResult:
    return PostTripSuggestionResult(
        destination="Kyoto",
        destinationCountry="Japan",
        durationDays=7,
        budgetEur=2500,
        description="Ancient temples, bamboo forests and seasonal Japanese cooking.",
        highlightsMatch=["culture", "food"],
        activities=[
            {
                "title": "Visit Fushimi Inari at dawn",
                "description": "Orange torii gates without the midday crowd.",
                "category": "CULTURE",
                "estimatedCost": 0.0,
            },
            {
                "title": "Kaiseki dinner in Gion",
                "description": "Seasonal seven-course tasting at an old machiya.",
                "category": "FOOD",
                "estimatedCost": 110.0,
            },
            {
                "title": "Arashiyama bamboo grove walk",
                "description": "Quiet morning loop through the western hills.",
                "category": "NATURE",
                "estimatedCost": 0.0,
            },
        ],
        matchedIata="KIX",
        matchScore=0.81,
    )


class TestSuggestPostTrip:
    def test_success(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripSuggester.suggest_next_trip",
                AsyncMock(return_value=_suggestion_result()),
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
        assert body["suggestion"]["highlightsMatch"] == ["culture", "food"]
        assert len(body["suggestion"]["activities"]) == 3
        incr.assert_called_once()

    def test_no_feedback_returns_400_and_no_quota_increment(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripSuggester.suggest_next_trip",
                AsyncMock(side_effect=AppError("NO_FEEDBACK_HISTORY", 400, "No feedback")),
            ),
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ) as incr,
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "NO_FEEDBACK_HISTORY"
        incr.assert_not_called()

    def test_propagates_accept_language_header(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripSuggester.suggest_next_trip",
                AsyncMock(return_value=_suggestion_result()),
            ) as suggest,
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ),
        ):
            response = client.post(
                "/v1/ai/post-trip-suggestion",
                headers={"Accept-Language": "fr-FR,fr;q=0.9"},
            )

        assert response.status_code == 200
        suggest.assert_called_once()
        assert suggest.call_args.kwargs.get("locale") == "fr"

    def test_defaults_to_english_when_no_header(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.ai.post_trip_routes.PostTripSuggester.suggest_next_trip",
                AsyncMock(return_value=_suggestion_result()),
            ) as suggest,
            patch(
                "src.api.ai.post_trip_routes.PlanService.increment_ai_generation",
            ),
        ):
            response = client.post("/v1/ai/post-trip-suggestion")

        assert response.status_code == 200
        assert suggest.call_args.kwargs.get("locale") == "en"
