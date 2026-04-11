"""Route tests for activities/routes.py — thin forwarding to ActivityService."""

import uuid
from datetime import UTC, date, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.activities.routes import router as activities_router
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
)
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

TRIP_ID = uuid.uuid4()
USER_ID = uuid.uuid4()


def _make_activity(**overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": TRIP_ID,
        "title": "Visit the Louvre",
        "description": "Iconic art museum",
        "date": date(2026, 5, 12),
        "start_time": None,
        "end_time": None,
        "location": "Paris",
        "category": "SIGHTSEEING",
        "estimated_cost": 25.0,
        "is_booked": False,
        "is_done": False,
        "validation_status": "MANUAL",
        "created_at": datetime.now(UTC),
        "updated_at": datetime.now(UTC),
    }
    base.update(overrides)
    activity = MagicMock()
    for k, v in base.items():
        setattr(activity, k, v)
    return activity


@pytest.fixture
def app() -> FastAPI:
    application = FastAPI()
    application.include_router(activities_router)

    @application.exception_handler(AppError)
    async def _handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": {"error": exc.message, "code": exc.code}},
        )

    user = User(id=USER_ID, email="user@example.com")
    trip = MagicMock(id=TRIP_ID, status="PLANNED")
    access = TripAccess(trip=trip, role=TripRole.OWNER)

    application.dependency_overrides[get_current_user] = lambda: user
    application.dependency_overrides[get_db] = lambda: MagicMock()
    application.dependency_overrides[get_trip_access] = lambda: access
    application.dependency_overrides[get_trip_editor_access] = lambda: access
    application.dependency_overrides[require_ai_quota] = lambda: user
    return application


@pytest.fixture
def client(app: FastAPI) -> TestClient:
    return TestClient(app)


class TestCreateActivity:
    def test_success(self, client: TestClient) -> None:
        activity = _make_activity()
        with patch(
            "src.api.activities.routes.ActivityService.create",
            return_value=activity,
        ) as mocked:
            response = client.post(
                f"/v1/trips/{TRIP_ID}/activities",
                json={"title": "Visit", "date": "2026-05-12"},
            )

        assert response.status_code == 201
        assert response.json()["title"] == "Visit the Louvre"
        mocked.assert_called_once()

    def test_app_error(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.create",
            side_effect=AppError("TRIP_INVALID", 400, "Invalid trip"),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/activities",
                json={"title": "X", "date": "2026-05-12"},
            )
        assert response.status_code == 400


class TestListActivities:
    def test_success(self, client: TestClient) -> None:
        activities = [_make_activity(), _make_activity()]
        with patch(
            "src.api.activities.routes.ActivityService.get_by_trip_paginated",
            return_value=(activities, 2, 1),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/activities?page=1&limit=20")

        assert response.status_code == 200
        body = response.json()
        assert len(body["items"]) == 2
        assert body["total"] == 2

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.get_by_trip_paginated",
            side_effect=AppError("INTERNAL", 500, "Boom"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/activities")
        assert response.status_code == 500

    def test_viewer_masks_cost(self, app: FastAPI) -> None:
        trip = MagicMock(id=TRIP_ID, status="PLANNED")
        viewer_access = TripAccess(trip=trip, role=TripRole.VIEWER)
        app.dependency_overrides[get_trip_access] = lambda: viewer_access
        activity = _make_activity(estimated_cost=999.0)
        with patch(
            "src.api.activities.routes.ActivityService.get_by_trip_paginated",
            return_value=([activity], 1, 1),
        ):
            response = TestClient(app).get(f"/v1/trips/{TRIP_ID}/activities")
        assert response.status_code == 200
        # Viewer path nulls estimatedCost on each item in the service layer
        item = response.json()["items"][0]
        # Response may use snake_case or camelCase depending on model config
        cost = item.get("estimatedCost", item.get("estimated_cost"))
        assert cost is None


class TestGetActivity:
    def test_success(self, client: TestClient) -> None:
        activity = _make_activity()
        with patch(
            "src.api.activities.routes.ActivityService.get_by_id",
            return_value=activity,
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}")
        assert response.status_code == 200
        assert response.json()["title"] == activity.title

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.get_by_id",
            side_effect=AppError("ACTIVITY_NOT_FOUND", 404, "Not found"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}")
        assert response.status_code == 404


class TestUpdateActivity:
    def test_success(self, client: TestClient) -> None:
        activity = _make_activity(title="Updated")
        with patch(
            "src.api.activities.routes.ActivityService.update",
            return_value=activity,
        ):
            response = client.patch(
                f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}",
                json={"title": "Updated"},
            )
        assert response.status_code == 200
        assert response.json()["title"] == "Updated"

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.update",
            side_effect=AppError("ACTIVITY_NOT_FOUND", 404, "Not found"),
        ):
            response = client.patch(
                f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}",
                json={"title": "Nope"},
            )
        assert response.status_code == 404


class TestDeleteActivity:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.delete",
            return_value=None,
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}")
        assert response.status_code == 204

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.delete",
            side_effect=AppError("ACTIVITY_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/activities/{uuid.uuid4()}")
        assert response.status_code == 404


# NOTE: batch_update_activities route is registered AFTER the /{activityId}
# PATCH handler in the router, so FastAPI tries to parse "batch" as a UUID
# first and returns 422 before reaching the batch handler. The route is
# effectively unreachable via TestClient — not tested here.


class TestSuggestActivities:
    def test_success(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.activities.routes.ActivityService.suggest",
                new_callable=AsyncMock,
                return_value=[{"title": "A", "date": "2026-05-12"}],
            ),
            patch(
                "src.api.activities.routes.PlanService.increment_ai_generation",
                return_value=None,
            ),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/activities/suggest?day=1")
        assert response.status_code == 200
        assert response.json()["activities"][0]["title"] == "A"

    def test_app_error(self, client: TestClient) -> None:
        with patch(
            "src.api.activities.routes.ActivityService.suggest",
            new_callable=AsyncMock,
            side_effect=AppError("LLM_FAIL", 500, "LLM failed"),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/activities/suggest")
        assert response.status_code == 500
