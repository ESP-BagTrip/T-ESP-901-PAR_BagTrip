"""Route tests for notifications/routes.py — list/unread/mark read."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.notifications.routes import router as notifications_router
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
    app.include_router(notifications_router)
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


def _make_notif(**overrides):
    n = MagicMock()
    n.id = overrides.get("id", uuid.uuid4())
    n.type = overrides.get("type", "DEPARTURE_REMINDER")
    n.title = overrides.get("title", "Your trip is coming up")
    n.body = overrides.get("body", "Get ready!")
    n.data = overrides.get("data")
    n.is_read = overrides.get("is_read", False)
    n.trip_id = overrides.get("trip_id")
    n.sent_at = overrides.get("sent_at")
    n.created_at = overrides.get("created_at", datetime.now(UTC))
    return n


class TestListNotifications:
    def test_success(self, client: TestClient) -> None:
        items = [_make_notif() for _ in range(3)]
        with patch(
            "src.api.notifications.routes.NotificationService.get_for_user",
            return_value=(items, 3, 1, 2),
        ):
            response = client.get("/v1/notifications?page=1&limit=20")

        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 3
        assert body["total"] == 3
        assert body["unread_count"] == 2

    def test_empty(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.get_for_user",
            return_value=([], 0, 0, 0),
        ):
            response = client.get("/v1/notifications")
        assert response.status_code == 200
        assert response.json()["items"] == []


class TestUnreadCount:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.get_unread_count",
            return_value=7,
        ):
            response = client.get("/v1/notifications/unread-count")
        assert response.status_code == 200
        assert response.json() == {"count": 7}


class TestMarkRead:
    def test_success(self, client: TestClient) -> None:
        notif = _make_notif(is_read=True)
        with patch(
            "src.api.notifications.routes.NotificationService.mark_as_read",
            return_value=notif,
        ):
            response = client.patch(f"/v1/notifications/{notif.id}/read")
        assert response.status_code == 200
        body = response.json()
        assert body["is_read"] is True

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.mark_as_read",
            return_value=None,
        ):
            response = client.patch(f"/v1/notifications/{uuid.uuid4()}/read")
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "NOTIFICATION_NOT_FOUND"


class TestMarkAllRead:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.mark_all_as_read",
            return_value=12,
        ):
            response = client.post("/v1/notifications/read-all")
        assert response.status_code == 200
        assert response.json() == {"updated": 12}


class TestDeleteNotification:
    def test_success_returns_204(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.delete",
            return_value=True,
        ) as mock_delete:
            response = client.delete(f"/v1/notifications/{uuid.uuid4()}")
        assert response.status_code == 204
        assert response.content == b""
        mock_delete.assert_called_once()

    def test_not_found_returns_404(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationService.delete",
            return_value=False,
        ):
            response = client.delete(f"/v1/notifications/{uuid.uuid4()}")
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "NOTIFICATION_NOT_FOUND"


def _make_pref(**overrides) -> MagicMock:
    p = MagicMock()
    p.push_enabled = overrides.get("push_enabled", True)
    p.flight_reminders = overrides.get("flight_reminders", True)
    p.activity_reminders = overrides.get("activity_reminders", True)
    p.trip_updates = overrides.get("trip_updates", True)
    p.budget_alerts = overrides.get("budget_alerts", True)
    p.social = overrides.get("social", True)
    return p


class TestGetPreferences:
    def test_returns_defaults(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationPreferenceService.get_or_create",
            return_value=_make_pref(),
        ):
            response = client.get("/v1/notifications/preferences")
        assert response.status_code == 200
        body = response.json()
        # This router serializes responses by alias (snake_case), matching the
        # convention of the sibling NotificationResponse schema.
        assert body["push_enabled"] is True
        assert body["flight_reminders"] is True
        assert body["activity_reminders"] is True
        assert body["trip_updates"] is True
        assert body["budget_alerts"] is True
        assert body["social"] is True


class TestUpdatePreferences:
    def test_partial_update(self, client: TestClient) -> None:
        updated = _make_pref(push_enabled=False, social=False)
        with patch(
            "src.api.notifications.routes.NotificationPreferenceService.update",
            return_value=updated,
        ) as mock_update:
            response = client.patch(
                "/v1/notifications/preferences",
                json={"pushEnabled": False, "social": False},
            )
        assert response.status_code == 200
        body = response.json()
        assert body["push_enabled"] is False
        assert body["social"] is False
        assert body["flight_reminders"] is True
        kwargs = mock_update.call_args.kwargs
        assert kwargs["push_enabled"] is False
        assert kwargs["social"] is False
        # Omitted fields are passed through as None (ignored by the service).
        assert kwargs["flight_reminders"] is None

    def test_accepts_snake_case_alias(self, client: TestClient) -> None:
        with patch(
            "src.api.notifications.routes.NotificationPreferenceService.update",
            return_value=_make_pref(budget_alerts=False),
        ) as mock_update:
            response = client.patch(
                "/v1/notifications/preferences",
                json={"budget_alerts": False},
            )
        assert response.status_code == 200
        assert response.json()["budget_alerts"] is False
        assert mock_update.call_args.kwargs["budget_alerts"] is False
