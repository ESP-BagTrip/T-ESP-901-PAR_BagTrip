"""Route tests for budget_items/routes.py."""

import uuid
from datetime import UTC, date, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
)
from src.api.budget_items.routes import router as budget_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

TRIP_ID = uuid.uuid4()
USER_ID = uuid.uuid4()


def _make_budget_item(**overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": TRIP_ID,
        "label": "Dinner",
        "amount": 45.0,
        "category": "FOOD",
        "date": date(2026, 5, 12),
        "is_planned": True,
        "source_type": None,
        "source_id": None,
        "created_at": datetime.now(UTC),
        "updated_at": datetime.now(UTC),
    }
    base.update(overrides)
    item = MagicMock()
    for k, v in base.items():
        setattr(item, k, v)
    return item


def _make_trip(**overrides):
    trip = MagicMock()
    trip.id = overrides.get("id", TRIP_ID)
    trip.status = overrides.get("status", "PLANNED")
    trip.destination_name = overrides.get("destination_name", "Barcelona")
    trip.destination_iata = overrides.get("destination_iata", "BCN")
    trip.origin_iata = overrides.get("origin_iata", "CDG")
    trip.start_date = overrides.get("start_date", date(2026, 5, 10))
    trip.end_date = overrides.get("end_date", date(2026, 5, 17))
    trip.nb_travelers = overrides.get("nb_travelers", 2)
    trip.activities = overrides.get("activities", [])
    trip.accommodations = overrides.get("accommodations", [])
    return trip


@pytest.fixture
def app() -> FastAPI:
    application = FastAPI()
    application.include_router(budget_router)

    @application.exception_handler(AppError)
    async def _handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": {"error": exc.message, "code": exc.code}},
        )

    user = User(id=USER_ID, email="user@example.com")
    trip = _make_trip()
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


def _override_viewer(app: FastAPI) -> None:
    trip = _make_trip()
    access = TripAccess(trip=trip, role=TripRole.VIEWER)
    app.dependency_overrides[get_trip_access] = lambda: access


class TestCreateBudgetItem:
    def test_success(self, client: TestClient) -> None:
        item = _make_budget_item()
        with (
            patch(
                "src.api.budget_items.routes.BudgetItemService.create",
                return_value=item,
            ),
            patch(
                "src.api.budget_items.routes.NotificationService.check_and_send_budget_alert",
                return_value=None,
            ),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/budget-items",
                json={"label": "Dinner", "amount": 45.0, "category": "FOOD"},
            )
        assert response.status_code == 201
        assert response.json()["label"] == "Dinner"

    def test_app_error(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.create",
            side_effect=AppError("VALIDATION", 400, "Bad input"),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/budget-items",
                json={"label": "X", "amount": 1.0},
            )
        assert response.status_code == 400


class TestListBudgetItems:
    def test_owner_success(self, client: TestClient) -> None:
        items = [_make_budget_item(), _make_budget_item(label="Taxi")]
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_by_trip",
            return_value=items,
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items")
        assert response.status_code == 200
        assert len(response.json()["items"]) == 2

    def test_viewer_empty(self, app: FastAPI) -> None:
        _override_viewer(app)
        response = TestClient(app).get(f"/v1/trips/{TRIP_ID}/budget-items")
        assert response.status_code == 200
        assert response.json()["items"] == []

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_by_trip",
            side_effect=AppError("INTERNAL", 500, "Boom"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items")
        assert response.status_code == 500


class TestBudgetSummary:
    def test_owner_success(self, client: TestClient) -> None:
        summary = {
            "total_budget": 1000.0,
            "total_spent": 200.0,
            "remaining": 800.0,
            "by_category": {"FOOD": 200.0},
            "percent_consumed": 20.0,
            "alert_level": None,
            "alert_message": None,
            "confirmed_total": 200.0,
            "forecasted_total": 0.0,
        }
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_budget_summary",
            return_value=summary,
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items/summary")
        assert response.status_code == 200
        body = response.json()
        assert body.get("totalBudget", body.get("total_budget")) == 1000.0

    def test_viewer_masks_spent(self, app: FastAPI) -> None:
        _override_viewer(app)
        summary = {
            "total_budget": 1000.0,
            "total_spent": 500.0,
            "remaining": 500.0,
            "by_category": {"FOOD": 500.0},
            "percent_consumed": 50.0,
            "alert_level": None,
            "alert_message": None,
            "confirmed_total": 500.0,
            "forecasted_total": 0.0,
        }
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_budget_summary",
            return_value=summary,
        ):
            response = TestClient(app).get(f"/v1/trips/{TRIP_ID}/budget-items/summary")
        assert response.status_code == 200
        body = response.json()
        # Viewer should see total_spent = 0, but percent_consumed from original
        assert body.get("totalSpent", body.get("total_spent")) == 0

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_budget_summary",
            side_effect=AppError("INTERNAL", 500, "Boom"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items/summary")
        assert response.status_code == 500


class TestGetBudgetItem:
    def test_owner_success(self, client: TestClient) -> None:
        item = _make_budget_item()
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_by_id",
            return_value=item,
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}")
        assert response.status_code == 200

    def test_viewer_forbidden(self, app: FastAPI) -> None:
        _override_viewer(app)
        response = TestClient(app).get(f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}")
        assert response.status_code == 403

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.get_by_id",
            side_effect=AppError("BUDGET_NOT_FOUND", 404, "Not found"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}")
        assert response.status_code == 404


class TestUpdateBudgetItem:
    def test_success(self, client: TestClient) -> None:
        item = _make_budget_item(amount=99.0)
        with (
            patch(
                "src.api.budget_items.routes.BudgetItemService.update",
                return_value=item,
            ),
            patch(
                "src.api.budget_items.routes.NotificationService.check_and_send_budget_alert",
                return_value=None,
            ),
        ):
            response = client.put(
                f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}",
                json={"amount": 99.0},
            )
        assert response.status_code == 200

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.update",
            side_effect=AppError("BUDGET_NOT_FOUND", 404, "Not found"),
        ):
            response = client.put(
                f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}",
                json={"amount": 99.0},
            )
        assert response.status_code == 404


class TestDeleteBudgetItem:
    def test_success(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.budget_items.routes.BudgetItemService.delete",
                return_value=None,
            ),
            patch(
                "src.api.budget_items.routes.NotificationService.check_and_send_budget_alert",
                return_value=None,
            ),
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}")
        assert response.status_code == 204

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.BudgetItemService.delete",
            side_effect=AppError("BUDGET_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/budget-items/{uuid.uuid4()}")
        assert response.status_code == 404


class TestEstimateBudget:
    def test_success(self, client: TestClient) -> None:
        estimation = {"total": 1500.0, "breakdown": {"food": 300}}
        with (
            patch(
                "src.agent.nodes.budget.budget_node",
                new_callable=AsyncMock,
                return_value={"budget_estimation": estimation},
            ),
            patch(
                "src.services.plan_service.PlanService.increment_ai_generation",
                return_value=None,
            ),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/budget/estimate")
        assert response.status_code == 200
        assert response.json()["estimation"]["total"] == 1500.0

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.agent.nodes.budget.budget_node",
            new_callable=AsyncMock,
            side_effect=AppError("LLM_FAIL", 500, "LLM failed"),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/budget/estimate")
        assert response.status_code == 500


class TestAcceptBudgetEstimate:
    def test_success(self, client: TestClient) -> None:
        with (
            patch(
                "src.api.budget_items.routes.TripsService.update_trip",
                return_value=None,
            ),
            patch(
                "src.api.budget_items.routes.NotificationService.check_and_send_budget_alert",
                return_value=None,
            ),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/budget/estimate/accept",
                json={"budget_total": 1500.0},
            )
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_app_error(self, client: TestClient) -> None:
        with patch(
            "src.api.budget_items.routes.TripsService.update_trip",
            side_effect=AppError("VALIDATION", 400, "Bad budget"),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/budget/estimate/accept",
                json={"budget_total": 1500.0},
            )
        assert response.status_code == 400
