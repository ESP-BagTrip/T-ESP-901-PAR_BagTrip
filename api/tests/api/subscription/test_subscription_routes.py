"""Unit tests for the subscription routes."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.subscription.routes import router as subscription_router
from src.config.database import get_db
from src.models.user import User
from src.utils.errors import AppError

app = FastAPI()
app.include_router(subscription_router)


@app.exception_handler(AppError)
async def _app_error_handler(_request: Request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": {"error": exc.message, "code": exc.code, **(exc.detail or {})}},
    )


@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_db_session():
    return MagicMock()


@pytest.fixture
def override_get_db(mock_db_session):
    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user():
    return User(id=uuid.uuid4(), email="test@example.com")


@pytest.fixture
def override_get_current_user(mock_user):
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


class TestCreateCheckout:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.create_checkout_session.return_value = {
            "url": "https://checkout.stripe.com/session_123"
        }
        response = client.post("/v1/subscription/checkout")
        assert response.status_code == 200

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_already_premium(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        mock_service.create_checkout_session.side_effect = AppError(
            "ALREADY_PREMIUM", 400, "You are already on a paid plan"
        )
        response = client.post("/v1/subscription/checkout")
        assert response.status_code == 400


class TestCreatePortal:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.create_portal_session.return_value = {"url": "https://billing.stripe.com/x"}
        response = client.post("/v1/subscription/portal")
        assert response.status_code == 200


class TestGetStatus:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.get_status.return_value = {"plan": "FREE"}
        response = client.get("/v1/subscription/status")
        assert response.status_code == 200
        assert response.json()["plan"] == "FREE"


class TestGetSubscriptionMe:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.get_subscription_details.return_value = {
            "plan": "PREMIUM",
            "cancel_at_period_end": False,
            "current_period_end": "2026-01-01T00:00:00+00:00",
            "payment_method": {"brand": "visa", "last4": "4242"},
        }
        response = client.get("/v1/subscription/me")
        assert response.status_code == 200
        assert response.json()["payment_method"]["last4"] == "4242"


class TestCancelSubscription:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.cancel_subscription.return_value = {
            "status": "scheduled_for_cancellation",
            "cancel_at_period_end": True,
            "current_period_end": "2026-01-01T00:00:00+00:00",
        }
        response = client.post("/v1/subscription/cancel")
        assert response.status_code == 200
        assert response.json()["cancel_at_period_end"] is True

    @patch("src.api.subscription.routes.SubscriptionService")
    def test_no_active_sub(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.cancel_subscription.side_effect = AppError(
            "NO_ACTIVE_SUBSCRIPTION", 400, "No active subscription to cancel"
        )
        response = client.post("/v1/subscription/cancel")
        assert response.status_code == 400


class TestReactivateSubscription:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.reactivate_subscription.return_value = {
            "status": "active",
            "cancel_at_period_end": False,
            "current_period_end": "2026-01-01T00:00:00+00:00",
        }
        response = client.post("/v1/subscription/reactivate")
        assert response.status_code == 200


class TestListInvoices:
    @patch("src.api.subscription.routes.SubscriptionService")
    def test_success(self, mock_service, client, override_get_current_user, override_get_db):
        mock_service.list_invoices.return_value = [
            {"id": "in_1", "status": "paid", "amount_paid": 999}
        ]
        response = client.get("/v1/subscription/invoices?limit=5")
        assert response.status_code == 200
        assert len(response.json()["invoices"]) == 1
        mock_service.list_invoices.assert_called_once()
        assert mock_service.list_invoices.call_args.kwargs["limit"] == 5

    def test_limit_out_of_range_rejected(self, client, override_get_current_user, override_get_db):
        """Schema validation: limit must be 1..50."""
        response = client.get("/v1/subscription/invoices?limit=999")
        assert response.status_code == 422
