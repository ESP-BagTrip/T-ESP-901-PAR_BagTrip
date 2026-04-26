"""Unit tests for StripePaymentsService."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.models.booking_intent import BookingIntent
from src.models.flight_offer import FlightOffer
from src.models.user import User
from src.services.stripe_payments_service import StripePaymentsService, _idem_key
from src.utils.errors import AppError


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestIdempotencyKey:
    """Idempotency key shape — a regression here means we'd silently lose dedup."""

    def test_idem_key_is_stable_per_intent_and_op(self):
        intent_id = uuid.UUID("00000000-0000-0000-0000-000000000001")
        assert _idem_key("authorize", intent_id) == _idem_key("authorize", intent_id)
        assert _idem_key("authorize", intent_id) != _idem_key("capture", intent_id)


class TestStripePaymentsService:
    """Tests for StripePaymentsService."""

    @patch("src.services.stripe_payments_service.StripeClient")
    @patch("src.services.stripe_payments_service.StripeProductsService")
    def test_create_manual_capture_payment_intent_success(
        self, mock_products, mock_client, mock_db_session
    ):
        """Authorize: passes idempotency key + flight metadata + customer to Stripe."""
        intent_id = uuid.uuid4()
        user_id = uuid.uuid4()
        offer_id = uuid.uuid4()

        intent = BookingIntent(
            id=intent_id,
            user_id=user_id,
            status="INIT",
            amount=100.0,
            currency="EUR",
            type="flight",
            trip_id=uuid.uuid4(),
            selected_offer_type="flight_offer",
            selected_offer_id=offer_id,
        )
        user = User(id=user_id, stripe_customer_id="cus_123")
        flight_offer = FlightOffer(
            id=offer_id,
            offer_json={
                "itineraries": [
                    {
                        "segments": [
                            {
                                "departure": {"iataCode": "PAR", "at": "2025-12-01"},
                                "arrival": {"iataCode": "NYC"},
                            },
                            {"departure": {"iataCode": "NYC"}, "arrival": {"iataCode": "PAR"}},
                        ]
                    }
                ]
            },
            validating_airline_codes="AF",
            amadeus_offer_id="1",
        )

        mock_db_session.query.return_value.filter.return_value.first.side_effect = [
            intent,
            user,
            flight_offer,
        ]
        mock_products.get_product_id.return_value = "prod_123"

        mock_pi = MagicMock(
            id="pi_123", client_secret="secret_123", status="requires_payment_method"
        )
        mock_client.create_payment_intent.return_value = mock_pi

        result = StripePaymentsService.create_manual_capture_payment_intent(
            mock_db_session, intent_id, user_id
        )

        assert result["stripePaymentIntentId"] == "pi_123"
        assert intent.stripe_payment_intent_id == "pi_123"
        call_kwargs = mock_client.create_payment_intent.call_args.kwargs
        assert call_kwargs["idempotency_key"] == _idem_key("authorize", intent_id)
        assert "Flight: PAR → PAR" in call_kwargs["description"]
        assert call_kwargs["metadata"]["flight_origin"] == "PAR"

    def test_create_pi_invalid_status(self, mock_db_session):
        intent = BookingIntent(status="AUTHORIZED")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.create_manual_capture_payment_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "INVALID_STATUS"

    def test_create_pi_missing_customer(self, mock_db_session):
        intent = BookingIntent(status="INIT")
        user = User(stripe_customer_id=None)
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [intent, user]

        with pytest.raises(AppError) as exc:
            StripePaymentsService.create_manual_capture_payment_intent(
                mock_db_session, uuid.uuid4(), uuid.uuid4()
            )
        assert exc.value.code == "MISSING_STRIPE_CUSTOMER"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_capture_payment_success_from_booked(self, mock_client, mock_db_session):
        intent = BookingIntent(id=uuid.uuid4(), status="BOOKED", stripe_payment_intent_id="pi_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.capture_payment_intent.return_value = MagicMock(latest_charge="ch_123")

        result = StripePaymentsService.capture_payment(mock_db_session, intent.id, uuid.uuid4())

        assert result.status == "CAPTURED"
        assert result.stripe_charge_id == "ch_123"
        # Idempotency key passed through
        kwargs = mock_client.capture_payment_intent.call_args.kwargs
        assert kwargs["idempotency_key"] == _idem_key("capture", intent.id)

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_capture_payment_from_authorized_allowed_in_dev(self, mock_client, mock_db_session):
        """Non-prod allows skipping the BOOKED step for QA convenience."""
        intent = BookingIntent(
            id=uuid.uuid4(), status="AUTHORIZED", stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.capture_payment_intent.return_value = MagicMock(latest_charge="ch_123")

        with patch("src.services.stripe_payments_service.settings") as mock_settings:
            mock_settings.NODE_ENV = "development"
            result = StripePaymentsService.capture_payment(mock_db_session, intent.id, uuid.uuid4())
        assert result.status == "CAPTURED"

    def test_capture_payment_from_authorized_blocked_in_prod(self, mock_db_session):
        """Production must require BOOKED — we don't ship the QA shortcut."""
        intent = BookingIntent(
            id=uuid.uuid4(), status="AUTHORIZED", stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with patch("src.services.stripe_payments_service.settings") as mock_settings:
            mock_settings.NODE_ENV = "production"
            with pytest.raises(AppError) as exc:
                StripePaymentsService.capture_payment(mock_db_session, intent.id, uuid.uuid4())
        assert exc.value.code == "INVALID_STATUS"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_cancel_payment_success(self, mock_client, mock_db_session):
        intent = BookingIntent(
            id=uuid.uuid4(), status="AUTHORIZED", stripe_payment_intent_id="pi_123"
        )
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        result = StripePaymentsService.cancel_payment(mock_db_session, intent.id, uuid.uuid4())

        assert result.status == "CANCELLED"
        kwargs = mock_client.cancel_payment_intent.call_args.kwargs
        assert kwargs["idempotency_key"] == _idem_key("cancel", intent.id)

    @patch("stripe.PaymentIntent.confirm")
    def test_confirm_payment_test_card(self, mock_confirm, mock_db_session):
        intent = BookingIntent(id=uuid.uuid4(), stripe_payment_intent_id="pi_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        mock_confirm.return_value = MagicMock(
            status="requires_capture", id="pi_123", client_secret="secret"
        )

        result = StripePaymentsService.confirm_payment_with_test_card(
            mock_db_session, intent.id, uuid.uuid4()
        )

        assert result["status"] == "requires_capture"
        assert intent.status == "AUTHORIZED"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_refund_full_success_marks_refunded(self, mock_client, mock_db_session):
        """Full refund: status flips to REFUNDED."""
        intent = BookingIntent(id=uuid.uuid4(), status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.retrieve_charge.return_value = MagicMock(
            amount_captured=10000, amount_refunded=0
        )
        mock_client.create_refund.return_value = MagicMock()

        result = StripePaymentsService.refund_payment(mock_db_session, intent.id, uuid.uuid4())

        assert result.status == "REFUNDED"
        kwargs = mock_client.create_refund.call_args.kwargs
        assert kwargs["charge_id"] == "ch_123"
        assert "idempotency_key" in kwargs

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_refund_partial_keeps_captured(self, mock_client, mock_db_session):
        """Partial refund: status stays CAPTURED so further partial refunds remain possible."""
        intent = BookingIntent(id=uuid.uuid4(), status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.retrieve_charge.return_value = MagicMock(
            amount_captured=10000, amount_refunded=0
        )
        mock_client.create_refund.return_value = MagicMock()

        result = StripePaymentsService.refund_payment(
            mock_db_session, intent.id, uuid.uuid4(), amount=2000
        )
        assert result.status == "CAPTURED"

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_refund_amount_exceeds_remaining_rejected(self, mock_client, mock_db_session):
        """Cannot refund more than was captured (minus already-refunded)."""
        intent = BookingIntent(id=uuid.uuid4(), status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.retrieve_charge.return_value = MagicMock(
            amount_captured=10000, amount_refunded=8000
        )

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(
                mock_db_session, intent.id, uuid.uuid4(), amount=5000
            )
        assert exc.value.code == "REFUND_AMOUNT_EXCEEDS_REMAINING"
        mock_client.create_refund.assert_not_called()

    @patch("src.services.stripe_payments_service.StripeClient")
    def test_refund_already_fully_refunded_rejected(self, mock_client, mock_db_session):
        """Charge already fully refunded → reject explicitly with a useful code."""
        intent = BookingIntent(id=uuid.uuid4(), status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent
        mock_client.retrieve_charge.return_value = MagicMock(
            amount_captured=10000, amount_refunded=10000
        )

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, intent.id, uuid.uuid4())
        assert exc.value.code == "ALREADY_FULLY_REFUNDED"
        mock_client.create_refund.assert_not_called()

    def test_refund_invalid_reason_rejected(self, mock_db_session):
        """Schema-level guard against non-Stripe refund reasons."""
        intent = BookingIntent(id=uuid.uuid4(), status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(
                mock_db_session, intent.id, uuid.uuid4(), reason="bogus_reason"
            )
        assert exc.value.code == "INVALID_REFUND_REASON"

    def test_refund_invalid_amount_rejected(self, mock_db_session):
        """Negative / zero amounts are rejected before we reach Stripe."""
        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(
                mock_db_session, uuid.uuid4(), uuid.uuid4(), amount=0
            )
        assert exc.value.code == "INVALID_AMOUNT"

    def test_refund_payment_invalid_status(self, mock_db_session):
        intent = BookingIntent(status="AUTHORIZED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "INVALID_STATUS"

    def test_refund_payment_missing_charge_id(self, mock_db_session):
        intent = BookingIntent(status="CAPTURED", stripe_charge_id=None)
        mock_db_session.query.return_value.filter.return_value.first.return_value = intent

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "MISSING_CHARGE_ID"

    def test_refund_payment_not_found(self, mock_db_session):
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(AppError) as exc:
            StripePaymentsService.refund_payment(mock_db_session, uuid.uuid4(), uuid.uuid4())
        assert exc.value.code == "BOOKING_INTENT_NOT_FOUND"
