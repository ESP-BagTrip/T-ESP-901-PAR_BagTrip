"""Unit tests for the Stripe webhooks routes."""

import json
from unittest.mock import MagicMock, patch

import pytest
import stripe
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api.stripe.webhooks.routes import router as stripe_router
from src.config.database import get_db

# Setup the test app
app = FastAPI()
app.include_router(stripe_router)


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


class TestHandleStripeWebhook:
    """Tests for POST /v1/stripe/webhooks."""

    @patch("src.api.stripe.webhooks.routes.settings")
    @patch("src.api.stripe.webhooks.routes.stripe.Webhook.construct_event")
    @patch("src.api.stripe.webhooks.routes.StripeWebhooksService.process_event")
    def test_handle_stripe_webhook_with_secret_success(
        self, mock_process, mock_construct, mock_settings, client, override_get_db
    ):
        """Test successful webhook processing with STRIPE_WEBHOOK_SECRET."""
        mock_settings.STRIPE_WEBHOOK_SECRET = "whsec_test"

        mock_event = MagicMock()
        mock_construct.return_value = mock_event

        mock_stripe_event = MagicMock()
        mock_stripe_event.stripe_event_id = "evt_123"
        mock_process.return_value = mock_stripe_event

        response = client.post(
            "/v1/stripe/webhooks",
            content=json.dumps({"id": "evt_123"}),
            headers={"stripe-signature": "sig_123"}
        )

        assert response.status_code == 200
        assert response.json() == {"received": True, "event_id": "evt_123"}
        mock_construct.assert_called_once()
        mock_process.assert_called_once()

    @patch("src.api.stripe.webhooks.routes.settings")
    @patch("src.api.stripe.webhooks.routes.stripe.Event.construct_from")
    @patch("src.api.stripe.webhooks.routes.StripeWebhooksService.process_event")
    def test_handle_stripe_webhook_without_secret_success(
        self, mock_process, mock_construct_from, mock_settings, client, override_get_db
    ):
        """Test successful webhook processing without STRIPE_WEBHOOK_SECRET."""
        mock_settings.STRIPE_WEBHOOK_SECRET = None

        mock_event = MagicMock()
        mock_construct_from.return_value = mock_event

        mock_stripe_event = MagicMock()
        mock_stripe_event.stripe_event_id = "evt_123"
        mock_process.return_value = mock_stripe_event

        response = client.post(
            "/v1/stripe/webhooks",
            content=json.dumps({"id": "evt_123"}),
            headers={"stripe-signature": "sig_123"}
        )

        assert response.status_code == 200
        assert response.json() == {"received": True, "event_id": "evt_123"}
        mock_construct_from.assert_called_once()
        mock_process.assert_called_once()

    @patch("src.api.stripe.webhooks.routes.settings")
    def test_handle_stripe_webhook_invalid_json(
        self, mock_settings, client, override_get_db
    ):
        """Test webhook processing with invalid JSON payload."""
        mock_settings.STRIPE_WEBHOOK_SECRET = None

        response = client.post(
            "/v1/stripe/webhooks",
            content="invalid json",
            headers={"stripe-signature": "sig_123"}
        )

        assert response.status_code == 400
        assert response.json() == {"error": "Invalid payload"}

    @patch("src.api.stripe.webhooks.routes.settings")
    @patch("src.api.stripe.webhooks.routes.stripe.Webhook.construct_event")
    def test_handle_stripe_webhook_invalid_signature(
        self, mock_construct, mock_settings, client, override_get_db
    ):
        """Test webhook processing with invalid signature."""
        mock_settings.STRIPE_WEBHOOK_SECRET = "whsec_test"
        mock_construct.side_effect = stripe.error.SignatureVerificationError("Invalid sig", "sig")

        response = client.post(
            "/v1/stripe/webhooks",
            content=json.dumps({"id": "evt_123"}),
            headers={"stripe-signature": "invalid_sig"}
        )

        assert response.status_code == 400
        assert response.json() == {"error": "Invalid signature"}

    @patch("src.api.stripe.webhooks.routes.settings")
    @patch("src.api.stripe.webhooks.routes.StripeWebhooksService.process_event")
    def test_handle_stripe_webhook_internal_error(
        self, mock_process, mock_settings, client, override_get_db
    ):
        """Test webhook processing with internal server error."""
        mock_settings.STRIPE_WEBHOOK_SECRET = None
        mock_process.side_effect = Exception("Internal Error")

        response = client.post(
            "/v1/stripe/webhooks",
            content=json.dumps({"id": "evt_123"}),
            headers={"stripe-signature": "sig_123"}
        )

        assert response.status_code == 500
        assert response.json() == {"error": "Internal Error"}
