"""Route tests for device_tokens/routes.py — FCM register/unregister."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.device_tokens.routes import router as device_tokens_router
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
    app.include_router(device_tokens_router)
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


class TestRegisterDeviceToken:
    def test_success(self, client: TestClient) -> None:
        created = MagicMock()
        created.id = uuid.uuid4()
        created.fcm_token = "fcm-token-abc"
        created.platform = "ios"
        created.created_at = datetime.now(UTC)

        with patch(
            "src.api.device_tokens.routes.DeviceTokenService.register",
            return_value=created,
        ) as mocked:
            response = client.post(
                "/v1/device-tokens",
                json={"fcmToken": "fcm-token-abc", "platform": "ios"},
            )

        assert response.status_code == 201
        body = response.json()
        assert body["fcm_token"] == "fcm-token-abc"
        assert body["platform"] == "ios"
        mocked.assert_called_once()

    def test_service_error(self, client: TestClient) -> None:
        with patch(
            "src.api.device_tokens.routes.DeviceTokenService.register",
            side_effect=AppError("TOKEN_INVALID", 400, "Bad token"),
        ):
            response = client.post(
                "/v1/device-tokens",
                json={"fcmToken": "bad", "platform": "android"},
            )

        assert response.status_code == 400
        assert response.json()["detail"]["code"] == "TOKEN_INVALID"

    def test_missing_body_returns_422(self, client: TestClient) -> None:
        response = client.post("/v1/device-tokens", json={})
        assert response.status_code == 422


class TestUnregisterDeviceToken:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.device_tokens.routes.DeviceTokenService.unregister",
            return_value=None,
        ) as mocked:
            response = client.delete("/v1/device-tokens/fcm-token-abc")

        assert response.status_code == 204
        mocked.assert_called_once()

    def test_service_error(self, client: TestClient) -> None:
        with patch(
            "src.api.device_tokens.routes.DeviceTokenService.unregister",
            side_effect=AppError("TOKEN_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete("/v1/device-tokens/missing")

        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "TOKEN_NOT_FOUND"
