"""Unit tests for the payment routes."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from src.api.auth.admin_guard import require_admin
from src.api.auth.middleware import get_current_user
from src.api.payments.routes import router as payments_router
from src.config.database import get_db
from src.models.booking_intent import BookingIntent
from src.models.user import User
from src.utils.errors import AppError

app = FastAPI()
app.include_router(payments_router)


# Mirror the global AppError handler from `src.main` so dependency-level raises
# (`require_admin`) get the right JSON shape in tests.
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
    return User(id=uuid.uuid4(), email="test@example.com", plan="FREE")


@pytest.fixture
def mock_admin_user():
    return User(id=uuid.uuid4(), email="admin@example.com", plan="ADMIN")


@pytest.fixture
def override_get_current_user(mock_user):
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


@pytest.fixture
def override_require_admin(mock_admin_user):
    """For admin-only routes — install both get_current_user and require_admin."""
    app.dependency_overrides[get_current_user] = lambda: mock_admin_user
    app.dependency_overrides[require_admin] = lambda: mock_admin_user
    yield
    app.dependency_overrides = {}


class TestAuthorizePayment:
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_authorize_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_result = {
            "stripePaymentIntentId": "pi_123",
            "clientSecret": "secret_123",
            "status": "requires_payment_method",
        }
        mock_service.create_manual_capture_payment_intent.return_value = mock_result

        response = client.post(
            f"/v1/booking-intents/{intent_id}/payment/authorize",
            json={"returnUrl": "http://example.com/return"},
        )

        assert response.status_code == 200
        assert response.json() == mock_result
        mock_service.create_manual_capture_payment_intent.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_authorize_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_service.create_manual_capture_payment_intent.side_effect = AppError(
            "ERROR", 400, "Auth failed"
        )

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/authorize", json={})

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Auth failed"


class TestCapturePayment:
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_capture_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_intent = BookingIntent(
            id=intent_id, status="CAPTURED", stripe_payment_intent_id="pi_123"
        )
        mock_service.capture_payment.return_value = mock_intent

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/capture")

        assert response.status_code == 200
        data = response.json()
        assert data["bookingIntent"]["id"] == str(intent_id)
        assert data["stripe"]["paymentIntentId"] == "pi_123"

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_capture_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        mock_service.capture_payment.side_effect = AppError("ERROR", 400, "Capture failed")
        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/capture")
        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Capture failed"


class TestCancelPayment:
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_cancel_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_service.cancel_payment.return_value = BookingIntent(id=intent_id, status="CANCELLED")

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/cancel")

        assert response.status_code == 200
        assert response.json()["bookingIntent"]["status"] == "CANCELLED"

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_cancel_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        mock_service.cancel_payment.side_effect = AppError("ERROR", 400, "Cancel failed")
        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/cancel")
        assert response.status_code == 400


class TestRefundPayment:
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_service.refund_payment.return_value = BookingIntent(id=intent_id, status="REFUNDED")

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/refund", json={})
        assert response.status_code == 200
        assert response.json()["bookingIntent"]["status"] == "REFUNDED"

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        mock_service.refund_payment.side_effect = AppError(
            "INVALID_STATUS", 400, "Must be CAPTURED"
        )
        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/refund", json={})
        assert response.status_code == 400

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_partial(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        intent_id = uuid.uuid4()
        mock_service.refund_payment.return_value = BookingIntent(id=intent_id, status="CAPTURED")

        response = client.post(
            f"/v1/booking-intents/{intent_id}/payment/refund",
            json={"amount": 500, "reason": "requested_by_customer"},
        )
        assert response.status_code == 200
        # Service called with parsed args
        call_kwargs = mock_service.refund_payment.call_args.kwargs
        assert call_kwargs["amount"] == 500
        assert call_kwargs["reason"] == "requested_by_customer"

    def test_refund_payment_invalid_reason_rejected_at_schema(
        self, client, override_get_current_user, override_get_db
    ):
        """Schema-level enum: bogus reason → 422 before reaching service."""
        response = client.post(
            f"/v1/booking-intents/{uuid.uuid4()}/payment/refund",
            json={"reason": "not-a-valid-reason"},
        )
        assert response.status_code == 422

    def test_refund_payment_negative_amount_rejected_at_schema(
        self, client, override_get_current_user, override_get_db
    ):
        """Schema-level: amount must be positive."""
        response = client.post(
            f"/v1/booking-intents/{uuid.uuid4()}/payment/refund",
            json={"amount": -100},
        )
        assert response.status_code == 422


class TestConfirmPaymentTest:
    """confirm-test is admin-gated AND blocked in production."""

    @patch("src.api.payments.routes.StripePaymentsService")
    @patch("src.api.payments.routes.settings")
    def test_admin_can_confirm_in_dev(
        self, mock_settings, mock_service, client, override_require_admin, override_get_db
    ):
        mock_settings.NODE_ENV = "development"
        mock_service.confirm_payment_with_test_card.return_value = {
            "stripePaymentIntentId": "pi_123",
            "clientSecret": "secret_123",
            "status": "requires_capture",
        }

        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/confirm-test")
        assert response.status_code == 200

    @patch("src.api.payments.routes.StripePaymentsService")
    @patch("src.api.payments.routes.settings")
    def test_blocked_in_production_even_for_admin(
        self, mock_settings, mock_service, client, override_require_admin, override_get_db
    ):
        """Production must reject the route entirely — admin or not."""
        mock_settings.NODE_ENV = "production"

        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/confirm-test")
        assert response.status_code == 404
        mock_service.confirm_payment_with_test_card.assert_not_called()

    def test_non_admin_user_forbidden(self, client, override_get_current_user, override_get_db):
        """Plain authenticated user must be denied (require_admin guard)."""
        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/confirm-test")
        assert response.status_code == 403

    @patch("src.api.payments.routes.StripePaymentsService")
    @patch("src.api.payments.routes.settings")
    def test_service_error_propagated(
        self, mock_settings, mock_service, client, override_require_admin, override_get_db
    ):
        mock_settings.NODE_ENV = "development"
        mock_service.confirm_payment_with_test_card.side_effect = AppError(
            "ERROR", 400, "Confirm failed"
        )

        response = client.post(f"/v1/booking-intents/{uuid.uuid4()}/payment/confirm-test")
        assert response.status_code == 400
