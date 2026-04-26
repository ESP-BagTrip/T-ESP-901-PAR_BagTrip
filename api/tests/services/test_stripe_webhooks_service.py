"""Unit tests for the Stripe webhook dispatcher."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.models.user import User
from src.services.stripe_webhooks_service import StripeWebhooksService


@pytest.fixture
def mock_db_session():
    return MagicMock()


def _event(event_type: str, obj: dict, event_id: str = "evt_x") -> MagicMock:
    """Build a Stripe event mock that mirrors the real shape."""
    event = MagicMock()
    event.id = event_id
    event.type = event_type
    event.livemode = False
    event.to_dict.return_value = {}
    event.data.object = obj
    return event


class TestIdempotency:
    def test_returns_existing_event_when_already_processed(self, mock_db_session):
        """Duplicate Stripe deliveries short-circuit on the unique constraint."""
        existing = StripeEvent(stripe_event_id="evt_dup")
        mock_db_session.query.return_value.filter.return_value.first.return_value = existing

        result = StripeWebhooksService.process_event(mock_db_session, _event("any.type", {}))

        assert result.stripe_event_id == "evt_dup"
        mock_db_session.add.assert_not_called()

    def test_unknown_event_type_persists_with_no_handler(self, mock_db_session):
        """Unknown events are still recorded in the audit log (no handler runs)."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        result = StripeWebhooksService.process_event(mock_db_session, _event("payout.created", {}))

        assert result.processed_at is not None
        assert result.processing_error is None


class TestPaymentEvents:
    def test_amount_capturable_updated_authorizes_intent(self, mock_db_session):
        intent = BookingIntent(status="INIT")
        booking_intent_id = uuid.uuid4()
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "payment_intent.amount_capturable_updated",
                {"metadata": {"booking_intent_id": str(booking_intent_id)}},
            ),
        )
        assert intent.status == "AUTHORIZED"

    def test_payment_intent_succeeded_marks_captured(self, mock_db_session):
        intent = BookingIntent(status="BOOKED")
        booking_intent_id = uuid.uuid4()
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "payment_intent.succeeded",
                {
                    "metadata": {"booking_intent_id": str(booking_intent_id)},
                    "latest_charge": "ch_456",
                },
            ),
        )
        assert intent.status == "CAPTURED"
        assert intent.stripe_charge_id == "ch_456"

    def test_payment_intent_canceled(self, mock_db_session):
        intent = BookingIntent(status="AUTHORIZED")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "payment_intent.canceled",
                {"metadata": {"booking_intent_id": str(uuid.uuid4())}},
            ),
        )
        assert intent.status == "CANCELLED"

    def test_payment_intent_failed(self, mock_db_session):
        intent = BookingIntent(status="INIT")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "payment_intent.payment_failed",
                {"metadata": {"booking_intent_id": str(uuid.uuid4())}},
            ),
        )
        assert intent.status == "FAILED"
        assert intent.last_error["type"] == "payment_failed"


class TestSubscriptionEvents:
    def test_subscription_created_sets_premium(self, mock_db_session):
        user = User(id=uuid.uuid4(), plan="FREE", stripe_customer_id="cus_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "customer.subscription.created",
                {
                    "customer": "cus_123",
                    "id": "sub_123",
                    "current_period_end": 1735689600,
                },
            ),
        )
        assert user.plan == "PREMIUM"
        assert user.stripe_subscription_id == "sub_123"

    def test_subscription_created_does_not_overwrite_admin(self, mock_db_session):
        """Admin must never be silently downgraded to PREMIUM by a webhook."""
        user = User(id=uuid.uuid4(), plan="ADMIN", stripe_customer_id="cus_admin")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "customer.subscription.created",
                {"customer": "cus_admin", "id": "sub_admin", "current_period_end": 1735689600},
            ),
        )
        assert user.plan == "ADMIN"

    def test_subscription_deleted_clears(self, mock_db_session):
        user = User(
            id=uuid.uuid4(),
            plan="PREMIUM",
            stripe_customer_id="cus_123",
            stripe_subscription_id="sub_123",
        )
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event("customer.subscription.deleted", {"customer": "cus_123", "id": "sub_123"}),
        )
        assert user.plan == "FREE"
        assert user.stripe_subscription_id is None

    def test_subscription_updated_canceled_status(self, mock_db_session):
        user = User(
            id=uuid.uuid4(),
            plan="PREMIUM",
            stripe_customer_id="cus_123",
            stripe_subscription_id="sub_123",
        )
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "customer.subscription.updated",
                {
                    "customer": "cus_123",
                    "status": "canceled",
                    "current_period_end": 1735689600,
                },
            ),
        )
        assert user.plan == "FREE"
        assert user.stripe_subscription_id is None


class TestInvoiceEvents:
    def test_invoice_payment_succeeded_extends_period(self, mock_db_session):
        user = User(id=uuid.uuid4(), plan="FREE", stripe_customer_id="cus_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "invoice.payment_succeeded",
                {
                    "customer": "cus_123",
                    "lines": {"data": [{"period": {"end": 1735689600}}]},
                },
            ),
        )
        assert user.plan == "PREMIUM"

    def test_invoice_payment_failed_logs_only(self, mock_db_session):
        """Failed payment doesn't downgrade — Stripe runs its own dunning retries first."""
        user = User(id=uuid.uuid4(), plan="PREMIUM", stripe_customer_id="cus_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "invoice.payment_failed",
                {"customer": "cus_123", "id": "in_123", "attempt_count": 1},
            ),
        )
        # State unchanged — handler is just observability
        assert user.plan == "PREMIUM"


class TestChargeEvents:
    def test_charge_refunded_full_marks_refunded(self, mock_db_session):
        intent = BookingIntent(status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "charge.refunded",
                {"id": "ch_123", "refunded": True, "amount": 10000, "amount_refunded": 10000},
            ),
        )
        assert intent.status == "REFUNDED"

    def test_charge_refunded_partial_keeps_captured(self, mock_db_session):
        """Partial refund: keep CAPTURED so further partial refunds remain possible."""
        intent = BookingIntent(status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "charge.refunded",
                {"id": "ch_123", "refunded": False, "amount": 10000, "amount_refunded": 3000},
            ),
        )
        assert intent.status == "CAPTURED"

    def test_charge_dispute_created_logs_only(self, mock_db_session):
        """Dispute event doesn't auto-mutate state — admin reviews on Stripe dashboard."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        result = StripeWebhooksService.process_event(
            mock_db_session,
            _event(
                "charge.dispute.created",
                {"charge": "ch_123", "amount": 1000, "reason": "fraudulent"},
            ),
        )
        assert result.processed_at is not None
        assert result.processing_error is None


class TestErrorHandling:
    def test_handler_exception_recorded_not_raised(self, mock_db_session):
        """A buggy handler shouldn't take down the webhook endpoint."""
        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        with patch(
            "src.services.stripe_webhooks.service._DISPATCH",
            {"customer.subscription.created": MagicMock(side_effect=Exception("boom"))},
        ):
            result = StripeWebhooksService.process_event(
                mock_db_session,
                _event("customer.subscription.created", {"customer": "cus_x", "id": "sub_x"}),
            )

        assert result.processing_error is not None
        assert result.processing_error["error"] == "boom"
