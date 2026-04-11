"""Unit tests for the payment routes."""

import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.auth.middleware import get_current_user
from src.api.payments.routes import router as payments_router
from src.config.database import get_db
from src.models.booking_intent import BookingIntent
from src.models.user import User
from src.utils.errors import AppError

# Setup the test app
app = FastAPI()
app.include_router(payments_router)


@pytest.fixture
def client():
    """Provide a test client for the app."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def mock_db_session():
    """Mock the database session."""
    session = MagicMock()
    return session


@pytest.fixture
def override_get_db(mock_db_session):
    """Override the get_db dependency."""

    def _get_db():
        yield mock_db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides = {}


@pytest.fixture
def mock_user():
    """Create a mock user."""
    return User(id=uuid.uuid4(), email="test@example.com")


@pytest.fixture
def override_get_current_user(mock_user):
    """Override the get_current_user dependency."""
    app.dependency_overrides[get_current_user] = lambda: mock_user
    yield
    app.dependency_overrides = {}


class TestAuthorizePayment:
    """Tests for POST /v1/booking-intents/{intentId}/payment/authorize."""

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_authorize_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful payment authorization."""
        intent_id = uuid.uuid4()

        mock_result = {
            "stripePaymentIntentId": "pi_123",
            "clientSecret": "secret_123",
            "status": "requires_payment_method",
        }
        mock_service.create_manual_capture_payment_intent.return_value = mock_result

        payload = {"returnUrl": "http://example.com/return"}
        response = client.post(f"/v1/booking-intents/{intent_id}/payment/authorize", json=payload)

        assert response.status_code == 200
        assert response.json() == mock_result
        mock_service.create_manual_capture_payment_intent.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_authorize_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test authorization error."""
        intent_id = uuid.uuid4()
        mock_service.create_manual_capture_payment_intent.side_effect = AppError(
            "ERROR", 400, "Auth failed"
        )

        payload = {}
        response = client.post(f"/v1/booking-intents/{intent_id}/payment/authorize", json=payload)

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Auth failed"


class TestCapturePayment:
    """Tests for POST /v1/booking-intents/{intentId}/payment/capture."""

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_capture_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful payment capture."""
        intent_id = uuid.uuid4()

        mock_intent = BookingIntent(
            id=intent_id, status="BOOKED", stripe_payment_intent_id="pi_123"
        )
        mock_service.capture_payment.return_value = mock_intent

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/capture")

        assert response.status_code == 200
        data = response.json()
        assert data["bookingIntent"]["id"] == str(intent_id)
        assert data["stripe"]["paymentIntentId"] == "pi_123"
        mock_service.capture_payment.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_capture_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test capture error."""
        intent_id = uuid.uuid4()
        mock_service.capture_payment.side_effect = AppError("ERROR", 400, "Capture failed")

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/capture")

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Capture failed"


class TestCancelPayment:
    """Tests for POST /v1/booking-intents/{intentId}/payment/cancel."""

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_cancel_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful payment cancellation."""
        intent_id = uuid.uuid4()

        mock_intent = BookingIntent(id=intent_id, status="CANCELLED")
        mock_service.cancel_payment.return_value = mock_intent

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/cancel")

        assert response.status_code == 200
        data = response.json()
        assert data["bookingIntent"]["status"] == "CANCELLED"
        mock_service.cancel_payment.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_cancel_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test cancellation error."""
        intent_id = uuid.uuid4()
        mock_service.cancel_payment.side_effect = AppError("ERROR", 400, "Cancel failed")

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/cancel")

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Cancel failed"


class TestConfirmPaymentTest:
    """Tests for POST /v1/booking-intents/{intentId}/payment/confirm-test."""

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_confirm_payment_test_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful test payment confirmation."""
        intent_id = uuid.uuid4()

        mock_result = {
            "stripePaymentIntentId": "pi_123",
            "clientSecret": "secret_123",
            "status": "succeeded",
        }
        mock_service.confirm_payment_with_test_card.return_value = mock_result

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/confirm-test")

        assert response.status_code == 200
        assert response.json() == mock_result
        mock_service.confirm_payment_with_test_card.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_confirm_payment_test_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test test payment confirmation error."""
        intent_id = uuid.uuid4()
        mock_service.confirm_payment_with_test_card.side_effect = AppError(
            "ERROR", 400, "Confirm failed"
        )

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/confirm-test")

        assert response.status_code == 400
        assert response.json()["detail"]["error"] == "Confirm failed"

    @patch("src.api.payments.routes.settings")
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_confirm_payment_test_blocked_in_production(
        self, mock_service, mock_settings, client, override_get_current_user, override_get_db
    ):
        """Test that /confirm-test returns 404 in production."""
        mock_settings.NODE_ENV = "production"
        intent_id = uuid.uuid4()

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/confirm-test")

        assert response.status_code == 404
        mock_service.confirm_payment_with_test_card.assert_not_called()

    @patch("src.api.payments.routes.settings")
    @patch("src.api.payments.routes.StripePaymentsService")
    def test_confirm_payment_test_allowed_in_development(
        self, mock_service, mock_settings, client, override_get_current_user, override_get_db
    ):
        """Test that /confirm-test works in development."""
        mock_settings.NODE_ENV = "development"
        intent_id = uuid.uuid4()

        mock_result = {
            "stripePaymentIntentId": "pi_123",
            "clientSecret": "secret_123",
            "status": "succeeded",
        }
        mock_service.confirm_payment_with_test_card.return_value = mock_result

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/confirm-test")

        assert response.status_code == 200
        mock_service.confirm_payment_with_test_card.assert_called_once()


class TestRefundPayment:
    """Tests for POST /v1/booking-intents/{intentId}/payment/refund."""

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_success(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test successful payment refund."""
        intent_id = uuid.uuid4()
        mock_intent = BookingIntent(id=intent_id, status="REFUNDED")
        mock_service.refund_payment.return_value = mock_intent

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/refund", json={})
        assert response.status_code == 200
        data = response.json()
        assert data["bookingIntent"]["status"] == "REFUNDED"
        mock_service.refund_payment.assert_called_once()

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_error(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test refund error."""
        intent_id = uuid.uuid4()
        mock_service.refund_payment.side_effect = AppError(
            "INVALID_STATUS", 400, "Must be CAPTURED"
        )

        response = client.post(f"/v1/booking-intents/{intent_id}/payment/refund", json={})
        assert response.status_code == 400

    @patch("src.api.payments.routes.StripePaymentsService")
    def test_refund_payment_partial(
        self, mock_service, client, override_get_current_user, override_get_db
    ):
        """Test partial refund with amount."""
        intent_id = uuid.uuid4()
        mock_intent = BookingIntent(id=intent_id, status="REFUNDED")
        mock_service.refund_payment.return_value = mock_intent

        response = client.post(
            f"/v1/booking-intents/{intent_id}/payment/refund",
            json={"amount": 500, "reason": "requested_by_customer"},
        )
        assert response.status_code == 200
        mock_service.refund_payment.assert_called_once()
