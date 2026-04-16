"""Route tests for profile/routes.py — traveler profile CRUD + completion."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.profile.routes import router as profile_router
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
    app.include_router(profile_router)
    app.dependency_overrides[get_current_user] = lambda: current_user
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


def _make_profile(**overrides):
    profile = MagicMock()
    profile.id = overrides.get("id", uuid.uuid4())
    profile.travel_types = overrides.get("travel_types", ["BEACH", "CITY"])
    profile.travel_style = overrides.get("travel_style", "RELAXED")
    profile.budget = overrides.get("budget", "MID")
    profile.companions = overrides.get("companions", "FAMILY")
    profile.travel_frequency = overrides.get("travel_frequency", "QUARTERLY")
    profile.medical_constraints = overrides.get("medical_constraints")
    profile.is_completed = overrides.get("is_completed", True)
    profile.created_at = overrides.get("created_at", datetime.now(UTC))
    profile.updated_at = overrides.get("updated_at", datetime.now(UTC))
    return profile


class TestGetProfile:
    def test_success_existing(self, client: TestClient) -> None:
        profile = _make_profile()
        with patch(
            "src.api.profile.routes.ProfileService.get_profile",
            return_value=profile,
        ):
            response = client.get("/v1/profile")
        assert response.status_code == 200
        body = response.json()
        assert body["travelTypes"] == ["BEACH", "CITY"]
        assert body["isCompleted"] is True

    def test_creates_when_missing(self, client: TestClient) -> None:
        empty_profile = _make_profile(
            travel_types=None,
            travel_style=None,
            budget=None,
            companions=None,
            is_completed=False,
        )
        with (
            patch(
                "src.api.profile.routes.ProfileService.get_profile",
                return_value=None,
            ),
            patch(
                "src.api.profile.routes.ProfileService.create_or_update_profile",
                return_value=empty_profile,
            ) as mocked_create,
        ):
            response = client.get("/v1/profile")
        assert response.status_code == 200
        assert response.json()["isCompleted"] is False
        mocked_create.assert_called_once()


class TestUpdateProfile:
    def test_success(self, client: TestClient) -> None:
        profile = _make_profile()
        with patch(
            "src.api.profile.routes.ProfileService.create_or_update_profile",
            return_value=profile,
        ) as mocked:
            response = client.put(
                "/v1/profile",
                json={
                    "travelTypes": ["BEACH", "CITY"],
                    "travelStyle": "RELAXED",
                    "budget": "MID",
                    "companions": "FAMILY",
                    "travelFrequency": "QUARTERLY",
                },
            )
        assert response.status_code == 200
        assert response.json()["travelStyle"] == "RELAXED"
        mocked.assert_called_once()

    def test_partial_update(self, client: TestClient) -> None:
        profile = _make_profile(budget="LOW")
        with patch(
            "src.api.profile.routes.ProfileService.create_or_update_profile",
            return_value=profile,
        ):
            response = client.put("/v1/profile", json={"budget": "LOW"})
        assert response.status_code == 200
        assert response.json()["budget"] == "LOW"


class TestCheckCompletion:
    def test_complete(self, client: TestClient) -> None:
        with patch(
            "src.api.profile.routes.ProfileService.check_completion",
            return_value=(True, []),
        ):
            response = client.get("/v1/profile/completion")
        assert response.status_code == 200
        body = response.json()
        assert body["isCompleted"] is True
        assert body["missingFields"] == []

    def test_incomplete(self, client: TestClient) -> None:
        with patch(
            "src.api.profile.routes.ProfileService.check_completion",
            return_value=(False, ["travelTypes", "budget"]),
        ):
            response = client.get("/v1/profile/completion")
        assert response.status_code == 200
        body = response.json()
        assert body["isCompleted"] is False
        assert "travelTypes" in body["missingFields"]
