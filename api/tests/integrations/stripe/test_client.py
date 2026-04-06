"""Unit tests for the Stripe client integration."""

import importlib
from unittest.mock import MagicMock, patch

import stripe

from src.integrations.stripe import client as stripe_client_module
from src.integrations.stripe.client import StripeClient


class TestStripeClientInitialization:
    """Tests for the Stripe client module initialization."""

    def test_initialization_with_key(self):
        """Test module initialization when STRIPE_SECRET_KEY is set."""
        with patch("src.config.env.settings") as mock_settings:
            mock_settings.STRIPE_SECRET_KEY = "sk_test_key"
            with patch("stripe.api_key"):
                # We need to reload to trigger the module-level code
                importlib.reload(stripe_client_module)
                assert stripe.api_key == "sk_test_key"

    def test_initialization_without_key(self):
        """Test module initialization when STRIPE_SECRET_KEY is not set."""
        with patch("src.config.env.settings") as mock_settings:
            mock_settings.STRIPE_SECRET_KEY = None
            # Reset api_key to ensure we test it's NOT set
            stripe.api_key = None
            importlib.reload(stripe_client_module)
            assert stripe.api_key is None

class TestStripeClient:
    """Tests for the StripeClient class."""

    @patch("stripe.Customer.create")
    def test_create_customer(self, mock_customer_create):
        """Test creating a Stripe customer."""
        mock_customer_create.return_value = MagicMock(id="cus_123")

        # Test with name
        customer = StripeClient.create_customer("test@example.com", "Test User")
        assert customer.id == "cus_123"
        mock_customer_create.assert_called_with(email="test@example.com", name="Test User")

        # Test without name
        StripeClient.create_customer("test2@example.com")
        mock_customer_create.assert_called_with(email="test2@example.com")

    @patch("stripe.PaymentIntent.create")
    def test_create_payment_intent(self, mock_pi_create):
        """Test creating a Stripe PaymentIntent."""
        mock_pi_create.return_value = MagicMock(id="pi_123")

        # Test basic creation
        pi = StripeClient.create_payment_intent(1000, "EUR")
        assert pi.id == "pi_123"
        mock_pi_create.assert_called_with(
            amount=1000,
            currency="eur",
            capture_method="manual",
            metadata={}
        )

        # Test with all optional parameters
        metadata = {"trip_id": "trip_456"}
        StripeClient.create_payment_intent(
            amount=2000,
            currency="USD",
            metadata=metadata,
            capture_method="automatic",
            customer="cus_123",
            description="Test payment"
        )
        mock_pi_create.assert_called_with(
            amount=2000,
            currency="usd",
            capture_method="automatic",
            metadata=metadata,
            customer="cus_123",
            description="Test payment"
        )

    @patch("stripe.PaymentIntent.capture")
    def test_capture_payment_intent(self, mock_pi_capture):
        """Test capturing a Stripe PaymentIntent."""
        mock_pi_capture.return_value = MagicMock(id="pi_123")

        pi = StripeClient.capture_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_capture.assert_called_once_with("pi_123")

    @patch("stripe.PaymentIntent.cancel")
    def test_cancel_payment_intent(self, mock_pi_cancel):
        """Test cancelling a Stripe PaymentIntent."""
        mock_pi_cancel.return_value = MagicMock(id="pi_123")

        pi = StripeClient.cancel_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_cancel.assert_called_once_with("pi_123")

    @patch("stripe.PaymentIntent.retrieve")
    def test_retrieve_payment_intent(self, mock_pi_retrieve):
        """Test retrieving a Stripe PaymentIntent."""
        mock_pi_retrieve.return_value = MagicMock(id="pi_123")

        pi = StripeClient.retrieve_payment_intent("pi_123")
        assert pi.id == "pi_123"
        mock_pi_retrieve.assert_called_once_with("pi_123")

    @patch("stripe.Refund.create")
    def test_create_refund(self, mock_create):
        """Test creating a refund."""
        mock_refund = MagicMock()
        mock_create.return_value = mock_refund

        result = StripeClient.create_refund("ch_123")
        assert result == mock_refund
        mock_create.assert_called_once_with(charge="ch_123")

    @patch("stripe.Refund.create")
    def test_create_partial_refund(self, mock_create):
        """Test creating a partial refund."""
        mock_refund = MagicMock()
        mock_create.return_value = mock_refund

        result = StripeClient.create_refund("ch_123", amount=500, reason="requested_by_customer")
        assert result == mock_refund
        mock_create.assert_called_once_with(charge="ch_123", amount=500, reason="requested_by_customer")
