"""Route tests for flights/orders/routes.py — trip-scoped flight orders CRUD."""

import uuid
from datetime import UTC, datetime
from unittest.mock import MagicMock

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.trip_access import (
    TripAccess,
    TripRole,
    get_trip_access,
    get_trip_editor_access,
)
from src.api.flights.orders.routes import router as flight_orders_router
from src.config.database import get_db
from src.enums import FlightOrderStatus
from src.utils.errors import AppError


@pytest.fixture
def mock_db() -> MagicMock:
    db = MagicMock()
    db.query.return_value.filter.return_value.order_by.return_value.all.return_value = []
    db.query.return_value.filter.return_value.first.return_value = None
    return db


@pytest.fixture
def trip_id() -> uuid.UUID:
    return uuid.uuid4()


@pytest.fixture
def app(mock_db: MagicMock, trip_id: uuid.UUID) -> FastAPI:
    app = FastAPI()
    app.include_router(flight_orders_router)

    trip = MagicMock()
    trip.id = trip_id
    access_owner = TripAccess(trip=trip, role=TripRole.OWNER)

    app.dependency_overrides[get_trip_access] = lambda: access_owner
    app.dependency_overrides[get_trip_editor_access] = lambda: access_owner
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


def _make_order(**overrides):
    order = MagicMock()
    order.id = overrides.get("id", uuid.uuid4())
    order.status = overrides.get("status", FlightOrderStatus.CONFIRMED.value)
    order.booking_reference = overrides.get("booking_reference", "REF123")
    order.payment_id = overrides.get("payment_id", "pi_123")
    order.ticket_url = overrides.get("ticket_url", "https://ticket.example.com")
    order.created_at = overrides.get("created_at", datetime.now(UTC))
    return order


class TestListFlightOrders:
    def test_owner_sees_payment_id(
        self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID
    ) -> None:
        order = _make_order()
        mock_db.query.return_value.filter.return_value.order_by.return_value.all.return_value = [
            order
        ]
        response = client.get(f"/v1/trips/{trip_id}/flights/orders")
        assert response.status_code == 200
        body = response.json()
        assert len(body) == 1
        assert body[0]["paymentId"] == "pi_123"

    def test_viewer_payment_id_redacted(
        self,
        app: FastAPI,
        mock_db: MagicMock,
        trip_id: uuid.UUID,
    ) -> None:
        trip = MagicMock()
        trip.id = trip_id
        app.dependency_overrides[get_trip_access] = lambda: TripAccess(
            trip=trip, role=TripRole.VIEWER
        )
        client = TestClient(app)

        order = _make_order()
        mock_db.query.return_value.filter.return_value.order_by.return_value.all.return_value = [
            order
        ]
        response = client.get(f"/v1/trips/{trip_id}/flights/orders")
        assert response.status_code == 200
        assert response.json()[0]["paymentId"] is None


class TestGetFlightOrder:
    def test_success(self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID) -> None:
        order = _make_order()
        mock_db.query.return_value.filter.return_value.first.return_value = order
        response = client.get(f"/v1/trips/{trip_id}/flights/orders/{order.id}")
        assert response.status_code == 200
        assert response.json()["bookingReference"] == "REF123"

    def test_not_found(self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID) -> None:
        mock_db.query.return_value.filter.return_value.first.return_value = None
        response = client.get(f"/v1/trips/{trip_id}/flights/orders/{uuid.uuid4()}")
        assert response.status_code == 404
        assert response.json()["detail"]["code"] == "ORDER_NOT_FOUND"


class TestDeleteFlightOrder:
    def test_deletes_non_confirmed(
        self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID
    ) -> None:
        order = _make_order(status=FlightOrderStatus.CANCELLED.value)
        mock_db.query.return_value.filter.return_value.first.return_value = order
        response = client.delete(f"/v1/trips/{trip_id}/flights/orders/{order.id}")
        assert response.status_code == 204
        mock_db.delete.assert_called_once_with(order)
        mock_db.commit.assert_called_once()

    def test_confirmed_immutable(
        self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID
    ) -> None:
        order = _make_order(status=FlightOrderStatus.CONFIRMED.value)
        mock_db.query.return_value.filter.return_value.first.return_value = order
        response = client.delete(f"/v1/trips/{trip_id}/flights/orders/{order.id}")
        assert response.status_code == 403
        assert response.json()["detail"]["code"] == "CONFIRMED_FLIGHT_IMMUTABLE"

    def test_delete_not_found(
        self, client: TestClient, mock_db: MagicMock, trip_id: uuid.UUID
    ) -> None:
        mock_db.query.return_value.filter.return_value.first.return_value = None
        response = client.delete(f"/v1/trips/{trip_id}/flights/orders/{uuid.uuid4()}")
        assert response.status_code == 404
