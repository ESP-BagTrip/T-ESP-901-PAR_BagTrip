"""Route tests for health/routes.py — liveness + readiness probes."""

from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.health.routes import router as health_router
from src.config.database import get_db


@pytest.fixture
def mock_db() -> MagicMock:
    return MagicMock()


@pytest.fixture
def client(mock_db: MagicMock) -> TestClient:
    app = FastAPI()
    app.include_router(health_router)
    app.dependency_overrides[get_db] = lambda: mock_db
    return TestClient(app)


class TestLiveness:
    def test_health_ok(self, client: TestClient) -> None:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


class TestReadiness:
    def test_all_ok(self, client: TestClient) -> None:
        redis = MagicMock()
        with patch(
            "src.api.health.routes.get_redis_client",
            return_value=redis,
        ):
            response = client.get("/health/ready")
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == "ok"
        assert body["checks"] == {"database": "ok", "redis": "ok"}
        redis.ping.assert_called_once()

    def test_redis_unconfigured_is_skipped_not_failure(self, client: TestClient) -> None:
        with patch("src.api.health.routes.get_redis_client", return_value=None):
            response = client.get("/health/ready")
        assert response.status_code == 200
        assert response.json()["checks"]["redis"] == "skipped"
        assert response.json()["status"] == "ok"

    def test_redis_down_is_degraded_still_200(self, client: TestClient) -> None:
        redis = MagicMock()
        redis.ping.side_effect = RuntimeError("connection refused")
        with patch("src.api.health.routes.get_redis_client", return_value=redis):
            response = client.get("/health/ready")
        assert response.status_code == 200
        body = response.json()
        assert body["status"] == "degraded"
        assert body["checks"]["redis"] == "down"

    def test_database_down_returns_503(self, client: TestClient, mock_db: MagicMock) -> None:
        mock_db.execute.side_effect = RuntimeError("db gone")
        with patch("src.api.health.routes.get_redis_client", return_value=MagicMock()):
            response = client.get("/health/ready")
        assert response.status_code == 503
        body = response.json()
        assert body["status"] == "unavailable"
        assert body["checks"]["database"] == "down"
