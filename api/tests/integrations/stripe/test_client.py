"""Unit tests for the Stripe client integration."""

import importlib
from unittest.mock import MagicMock, patch

import stripe

from src.integrations.stripe import client as stripe_client_module
from src.integrations.stripe.client import STRIPE_API_VERSION, StripeClient


class TestStripeClientInitialization:
    """Tests for the Stripe client module initialization."""

    def test_initialization_with_key(self):
        """Test module initialization when STRIPE_SECRET_KEY is set."""
        with patch("src.config.env.settings") as mock_settings:
            mock_settings.STRIPE_SECRET_KEY = "sk_test_key"
            with patch("stripe.api_key"):
                importlib.reload(stripe_client_module)
                assert stripe.api_key == "sk_test_key"

    def test_initialization_pins_api_version(self):
        """Module init must pin Stripe API version when key is set."""
        with patch("src.config.env.settings") as mock_settings:
            mock_settings.STRIPE_SECRET_KEY = "sk_test_key"
            importlib.reload(stripe_client_module)
            assert stripe.api_version == STRIPE_API_VERSION

    def test_initialization_without_key(self):
        """Test module initialization when STRIPE_SECRET_KEY is not set."""
        with patch("src.config.env.settings") as mock_settings:
            mock_settings.STRIPE_SECRET_KEY = None
            stripe.api_key = None
            importlib.reload(stripe_client_module)
            assert stripe.api_key is None

    def test_api_version_constant(self):
        """The constant exists and matches what we deploy with."""
        assert STRIPE_API_VERSION == "2024-10-28.acacia"


class TestStripeClient:
    """Tests for the StripeClient class."""

    @patch("stripe.Customer.create")
    def test_create_customer(self, mock_customer_create):
        """Test creating a Stripe customer."""
        mock_customer_create.return_value = MagicMock(id="cus_123")

        customer = StripeClient.create_customer("test@example.com", "Test User")
        assert customer.id == "cus_123"
        mock_customer_create.assert_called_with(email="test@example.com", name="Test User")

        StripeClient.create_customer("test2@example.com")
        mock_customer_create.assert_called_with(email="test2@example.com")

    @patch("stripe.Customer.create")
    def test_create_customer_forwards_idempotency_key(self, mock_create):
        StripeClient.create_customer(email="x@y.z", name="X", idempotency_key="user-create-1")
        kwargs = mock_create.call_args.kwargs
        assert kwargs["idempotency_key"] == "user-create-1"

    @patch("stripe.PaymentIntent.create")
    def test_create_payment_intent(self, mock_pi_create):
        """Test creating a Stripe PaymentIntent."""
        mock_pi_create.return_value = MagicMock(id="pi_123")

        pi = StripeClient.create_payment_intent(1000, "EUR")
        assert pi.id == "pi_123"
        mock_pi_create.assert_called_with(
            amount=1000, currency="eur", capture_method="manual", metadata={}
        )

        metadata = {"trip_id": "trip_456"}
        StripeClient.create_payment_intent(
            amount=2000,
            currency="USD",
            metadata=metadata,
            capture_method="automatic",
            customer="cus_123",
            description="Test payment",
        )
        mock_pi_create.assert_called_with(
            amount=2000,
            currency="usd",
            capture_method="automatic",
            metadata=metadata,
            customer="cus_123",
            description="Test payment",
        )

    @patch("stripe.PaymentIntent.create")
    def test_create_payment_intent_forwards_idempotency_key(self, mock_create):
        StripeClient.create_payment_intent(
            amount=1000,
            currency="EUR",
            idempotency_key="bi-1-authorize-v1",
        )
        kwargs = mock_create.call_args.kwargs
        assert kwargs["idempotency_key"] == "bi-1-authorize-v1"

    @patch("stripe.PaymentIntent.capture")
    def test_capture_payment_intent(self, mock_pi_capture):
        mock_pi_capture.return_value = MagicMock(id="pi_123")
        pi = StripeClient.capture_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_capture.assert_called_once_with("pi_123")

    @patch("stripe.PaymentIntent.capture")
    def test_capture_payment_intent_forwards_idempotency_key(self, mock_capture):
        StripeClient.capture_payment_intent("pi_1", idempotency_key="bi-1-capture-v1")
        args = mock_capture.call_args
        assert args.args[0] == "pi_1"
        assert args.kwargs["idempotency_key"] == "bi-1-capture-v1"

    @patch("stripe.PaymentIntent.cancel")
    def test_cancel_payment_intent(self, mock_pi_cancel):
        mock_pi_cancel.return_value = MagicMock(id="pi_123")
        pi = StripeClient.cancel_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_cancel.assert_called_once_with("pi_123")

    @patch("stripe.PaymentIntent.retrieve")
    def test_retrieve_payment_intent(self, mock_pi_retrieve):
        mock_pi_retrieve.return_value = MagicMock(id="pi_123")
        pi = StripeClient.retrieve_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_retrieve.assert_called_once_with("pi_123")

    @patch("stripe.Refund.create")
    def test_create_refund(self, mock_create):
        mock_refund = MagicMock()
        mock_create.return_value = mock_refund
        result = StripeClient.create_refund("ch_123")
        assert result == mock_refund
        mock_create.assert_called_once_with(charge="ch_123")

    @patch("stripe.Refund.create")
    def test_create_partial_refund(self, mock_create):
        mock_refund = MagicMock()
        mock_create.return_value = mock_refund
        result = StripeClient.create_refund("ch_123", amount=500, reason="requested_by_customer")
        assert result == mock_refund
        mock_create.assert_called_once_with(
            charge="ch_123", amount=500, reason="requested_by_customer"
        )

    @patch("stripe.Refund.create")
    def test_create_refund_forwards_idempotency_key(self, mock_create):
        StripeClient.create_refund(
            charge_id="ch_1",
            amount=500,
            reason="requested_by_customer",
            idempotency_key="bi-1-refund-1",
        )
        kwargs = mock_create.call_args.kwargs
        assert kwargs["idempotency_key"] == "bi-1-refund-1"


class TestSubscriptionAndInvoiceHelpers:
    """New helpers added for the subscription lifecycle."""

    @patch("stripe.Charge.retrieve")
    def test_retrieve_charge(self, mock_retrieve):
        StripeClient.retrieve_charge("ch_1")
        mock_retrieve.assert_called_once_with("ch_1")

    @patch("stripe.Subscription.retrieve")
    def test_retrieve_subscription(self, mock_retrieve):
        StripeClient.retrieve_subscription("sub_1")
        mock_retrieve.assert_called_once_with("sub_1")

    @patch("stripe.Subscription.modify")
    def test_update_subscription_forwards_idempotency_key(self, mock_modify):
        StripeClient.update_subscription(
            "sub_1", idempotency_key="sub-cancel-1", cancel_at_period_end=True
        )
        args = mock_modify.call_args
        assert args.args[0] == "sub_1"
        assert args.kwargs["cancel_at_period_end"] is True
        assert args.kwargs["idempotency_key"] == "sub-cancel-1"

    @patch("stripe.Invoice.list")
    def test_list_invoices(self, mock_list):
        StripeClient.list_invoices("cus_1", limit=5)
        mock_list.assert_called_once_with(customer="cus_1", limit=5)

    @patch("stripe.PaymentMethod.retrieve")
    def test_retrieve_payment_method(self, mock_retrieve):
        StripeClient.retrieve_payment_method("pm_1")
        mock_retrieve.assert_called_once_with("pm_1")

    @patch("stripe.billing_portal.Session.create")
    def test_create_billing_portal_session(self, mock_create):
        mock_create.return_value = MagicMock(url="https://portal.stripe.com/x")
        result = StripeClient.create_billing_portal_session(
            customer_id="cus_1", return_url="bagtrip://profile"
        )
        kwargs = mock_create.call_args.kwargs
        assert kwargs["customer"] == "cus_1"
        assert kwargs["return_url"] == "bagtrip://profile"
        assert result.url == "https://portal.stripe.com/x"
