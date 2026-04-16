"""Route tests for invites/routes.py — accepting invite tokens."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.invites.routes import router as invites_router
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
    app.include_router(invites_router)
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


def _share_dict(**overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": uuid.uuid4(),
        "user_id": uuid.uuid4(),
        "role": "VIEWER",
        "invited_at": datetime.now(UTC),
        "user_email": "viewer@example.com",
        "user_full_name": "Viewer User",
    }
    base.update(overrides)
    return base


class TestAcceptInvite:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.invites.routes.TripShareService.accept_invite",
            return_value=_share_dict(),
        ) as mocked:
            response = client.post("/v1/invites/token-abc/accept")

        assert response.status_code == 200
        body = response.json()
        assert body["user_email"] == "viewer@example.com"
        assert body["role"] == "VIEWER"
        mocked.assert_called_once()

    def test_invite_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.invites.routes.TripShareService.accept_invite",
            side_effect=AppError("INVITE_NOT_FOUND", 404, "Not found"),
        ):
            response = client.post("/v1/invites/missing/accept")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "INVITE_NOT_FOUND"

    def test_invite_expired(self, client: TestClient) -> None:
        with patch(
            "src.api.invites.routes.TripShareService.accept_invite",
            side_effect=AppError("INVITE_EXPIRED", 410, "Expired"),
        ):
            response = client.post("/v1/invites/expired/accept")

        assert response.status_code == 410

    def test_already_shared(self, client: TestClient) -> None:
        with patch(
            "src.api.invites.routes.TripShareService.accept_invite",
            side_effect=AppError("ALREADY_SHARED", 409, "Already shared"),
        ):
            response = client.post("/v1/invites/tok/accept")

        assert response.status_code == 409
        assert response.json()["detail"]["code"] == "ALREADY_SHARED"
