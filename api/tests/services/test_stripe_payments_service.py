"""Unit tests for StripePaymentsService."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.models.booking_intent import BookingIntent
from src.models.user import User
from src.models.flight_offer import FlightOffer
from src.services.stripe_payments_service import StripePaymentsService
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestStripePaymentsService:
    """Tests for StripePaymentsService."""

    @patch("src.services.stripe_payments_service.StripeClient")
    @patch("src.services.stripe_payments_service.StripeProductsService")
    def test_create_manual_capture_payment_intent_success(
        self, mock_products, mock_client, mock_db_session
    ):
        """Test successful payment intent creation."""
        intent_id = uuid.uuid4()
        user_id = uuid.uuid4()
        offer_id = uuid.uuid4()
        
        # Mock intent
        intent = BookingIntent(
            id=intent_id,
            user_id=user_id,
            status="INIT",
            amount=100.0,
            currency="EUR",
            type="flight",
            trip_id=uuid.uuid4(),
            selected_offer_type="flight_offer",
            selected_offer_id=offer_id
        )
        
        # Mock user
        user = User(id=user_id, stripe_customer_id="cus_123")
        
        # Mock Flight Offer
        flight_offer = FlightOffer(
            id=offer_id,
            offer_json={
                "itineraries": [
                    {
                        "segments": [
                            {"departure": {"iataCode": "PAR", "at": "2025-12-01"}, "arrival": {"iataCode": "NYC"}},
                            {"departure": {"iataCode": "NYC"}, "arrival": {"iataCode": "PAR"}}
                        ]
                    }
                ]
            },
            validating_airline_codes="AF",
            amadeus_offer_id="1"
        )
        
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [intent, user, flight_offer]
        
        # Mock product ID
        mock_products.get_product_id.return_value = "prod_123"
        
        # Mock Stripe response
        mock_pi = MagicMock()
        mock_pi.id = "pi_123"
        mock_pi.client_secret = "secret_123"
        mock_pi.status = "requires_payment_method"
        mock_client.create_payment_intent.return_value = mock_pi
        
        result = StripePaymentsService.create_manual_capture_payment_intent(
            mock_db_session, intent_id, user_id
        )
        
        assert result["stripePaymentIntentId"] == "pi_123"
        assert intent.stripe_payment_intent_id == "pi_123"
        
        # Check metadata description
        call_args = mock_client.create_payment_intent.call_args
        assert "Flight: PAR → PAR" in call_args[1]["description"]
        assert call_args[1]["metadata"]["flight_origin"] == "PAR"

    def test_create_pi_invalid_status(self, mock_db_session):
        """Test error when intent status is invalid."""
        intent = BookingIntent(status="AUTHORIZED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        with pytest.raises(AppError) as exc:
            StripePaymentsService.create_manual_capture_payment_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "INVALID_STATUS"

    def test_create_pi_missing_customer(self, mock_db_session):
        """Test error when user has no stripe ID."""
        intent = BookingIntent(status="INIT")
        user = User(stripe_customer_id=None)
        
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [intent, user]
        
        with pytest.raises(AppError) as exc:
            StripePaymentsService.create_manual_capture_payment_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "MISSING_STRIPE_CUSTOMER"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_capture_payment_success(self, mock_client, mock_db_session):
        """Test successful payment capture."""
        intent = BookingIntent(
            id=uuid.uuid4(),
            status="BOOKED",
            stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        mock_pi = MagicMock()
        mock_pi.latest_charge = "ch_123"
        mock_client.capture_payment_intent.return_value = mock_pi
        
        result = StripePaymentsService.capture_payment(
            mock_db_session, intent.id, uuid.uuid4()
        )
        
        assert result.status == "CAPTURED"
        assert result.stripe_charge_id == "ch_123"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_cancel_payment_success(self, mock_client, mock_db_session):
        """Test successful payment cancellation."""
        intent = BookingIntent(
            id=uuid.uuid4(),
            status="AUTHORIZED",
            stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        
        result = StripePaymentsService.cancel_payment(
            mock_db_session, intent.id, uuid.uuid4()
        )
        
        assert result.status == "CANCELLED"
        mock_client.cancel_payment_intent.assert_called_once_with("pi_123")

    @patch("stripe.PaymentIntent.confirm")
    def test_confirm_payment_test_card(self, mock_confirm, mock_db_session):
        """Test confirming payment with test card."""
        intent = BookingIntent(
            id=uuid.uuid4(),
            stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        mock_pi = MagicMock()
        mock_pi.status = "requires_capture"
        mock_pi.id = "pi_123"
        mock_pi.client_secret = "secret"
        mock_confirm.return_value = mock_pi

        result = StripePaymentsService.confirm_payment_with_test_card(
            mock_db_session, intent.id, uuid.uuid4()
        )

        assert result["status"] == "requires_capture"
        assert intent.status == "AUTHORIZED"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_refund_payment_success(self, mock_client, mock_db_session):
        """Test successful payment refund."""
        intent = BookingIntent(
            id=uuid.uuid4(),
            status="CAPTURED",
            stripe_charge_id="ch_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.create_refund.return_value = MagicMock()

        result = StripePaymentsService.refund_payment(mock_db_session, intent.id, uuid.uuid4())
        assert result.status == "REFUNDED"
        mock_client.create_refund.assert_called_once_with(charge_id="ch_123", amount=None, reason=None)

    def test_refund_payment_invalid_status(self, mock_db_session):
        """Test refund error when status is not CAPTURED."""
        intent = BookingIntent(status="AUTHORIZED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "INVALID_STATUS"

    def test_refund_payment_missing_charge_id(self, mock_db_session):
        """Test refund error when no charge ID."""
        intent = BookingIntent(status="CAPTURED", stripe_charge_id=None)
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "MISSING_CHARGE_ID"

    def test_refund_payment_not_found(self, mock_db_session):
        """Test refund error when booking intent not found."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "BOOKING_INTENT_NOT_FOUND"
