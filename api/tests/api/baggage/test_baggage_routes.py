"""Route tests for baggage/routes.py — thin forwarding to BaggageItemsService."""

import uuid
from datetime import UTC, datetime
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
from src.api.baggage.routes import router as baggage_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

TRIP_ID = uuid.uuid4()
USER_ID = uuid.uuid4()


def _make_baggage(**overrides):
    base = {
        "id": uuid.uuid4(),
        "trip_id": TRIP_ID,
        "name": "Passport",
        "quantity": 1,
        "is_packed": False,
        "category": "DOCUMENTS",
        "notes": None,
        "created_at": datetime.now(UTC),
        "updated_at": datetime.now(UTC),
    }
    base.update(overrides)
    item = MagicMock()
    for k, v in base.items():
        setattr(item, k, v)
    return item


@pytest.fixture
def app() -> FastAPI:
    application = FastAPI()
    application.include_router(baggage_router)

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


class TestCreateBaggageItem:
    def test_success(self, client: TestClient) -> None:
        item = _make_baggage()
        with patch(
            "src.api.baggage.routes.BaggageItemsService.create_baggage_item",
            return_value=item,
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/baggage",
                json={"name": "Passport", "quantity": 1, "category": "DOCUMENTS"},
            )
        assert response.status_code == 201
        assert response.json()["name"] == "Passport"

    def test_app_error(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.create_baggage_item",
            side_effect=AppError("VALIDATION", 400, "Bad input"),
        ):
            response = client.post(
                f"/v1/trips/{TRIP_ID}/baggage",
                json={"name": "X"},
            )
        assert response.status_code == 400


class TestListBaggageItems:
    def test_success(self, client: TestClient) -> None:
        items = [_make_baggage(), _make_baggage(name="Toothbrush")]
        with patch(
            "src.api.baggage.routes.BaggageItemsService.get_baggage_items_by_trip",
            return_value=items,
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/baggage")
        assert response.status_code == 200
        assert len(response.json()["items"]) == 2

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.get_baggage_items_by_trip",
            side_effect=AppError("INTERNAL", 500, "Boom"),
        ):
            response = client.get(f"/v1/trips/{TRIP_ID}/baggage")
        assert response.status_code == 500


class TestUpdateBaggageItem:
    def test_success(self, client: TestClient) -> None:
        item = _make_baggage(is_packed=True)
        with patch(
            "src.api.baggage.routes.BaggageItemsService.update_baggage_item",
            return_value=item,
        ):
            response = client.patch(
                f"/v1/trips/{TRIP_ID}/baggage/{uuid.uuid4()}",
                json={"isPacked": True},
            )
        assert response.status_code == 200

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.update_baggage_item",
            side_effect=AppError("BAGGAGE_NOT_FOUND", 404, "Not found"),
        ):
            response = client.patch(
                f"/v1/trips/{TRIP_ID}/baggage/{uuid.uuid4()}",
                json={"isPacked": True},
            )
        assert response.status_code == 404


class TestDeleteBaggageItem:
    def test_success(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.delete_baggage_item",
            return_value=None,
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/baggage/{uuid.uuid4()}")
        assert response.status_code == 204

    def test_not_found(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.delete_baggage_item",
            side_effect=AppError("BAGGAGE_NOT_FOUND", 404, "Not found"),
        ):
            response = client.delete(f"/v1/trips/{TRIP_ID}/baggage/{uuid.uuid4()}")
        assert response.status_code == 404


class TestSuggestBaggage:
    def test_success(self, client: TestClient) -> None:
        items = [{"name": "Passport", "quantity": 1, "category": "DOCUMENTS"}]
        with (
            patch(
                "src.api.baggage.routes.BaggageItemsService.suggest_baggage_items",
                new_callable=AsyncMock,
                return_value=items,
            ),
            patch(
                "src.api.baggage.routes.PlanService.increment_ai_generation",
                return_value=None,
            ),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/baggage/suggest")
        assert response.status_code == 200
        assert response.json()["items"][0]["name"] == "Passport"

    def test_error(self, client: TestClient) -> None:
        with patch(
            "src.api.baggage.routes.BaggageItemsService.suggest_baggage_items",
            new_callable=AsyncMock,
            side_effect=AppError("LLM_FAIL", 500, "LLM failed"),
        ):
            response = client.post(f"/v1/trips/{TRIP_ID}/baggage/suggest")
        assert response.status_code == 500
