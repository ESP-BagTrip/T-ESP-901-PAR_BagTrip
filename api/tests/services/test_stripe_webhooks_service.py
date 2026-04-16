"""Unit tests for StripeWebhooksService."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.models.user import User
from src.services.stripe_webhooks_service import StripeWebhooksService


@pytest.fixture
def mock_db_session():
    """Mock database session."""
    return MagicMock()


class TestStripeWebhooksService:
    """Tests for StripeWebhooksService."""

    def test_process_event_existing(self, mock_db_session):
        """Test idempotency: event already processed."""
        event = MagicMock(id="evt_123")

        mock_db_session.query.return_value.filter.return_value.first.return_value = StripeEvent(
            stripe_event_id="evt_123"
        )

        result = StripeWebhooksService.process_event(mock_db_session, event)
        assert result.stripe_event_id == "evt_123"
        mock_db_session.add.assert_not_called()

        def test_process_event_new_authorized(self, mock_db_session):
            """Test processing payment_intent.amount_capturable_updated."""
            event = MagicMock()
            event.id = "evt_new"
            event.type = "payment_intent.amount_capturable_updated"
            event.livemode = False
            event.to_dict.return_value = {}
            event.data.object = {"metadata": {"booking_intent_id": str(uuid.uuid4())}}

            intent = BookingIntent(status="INIT")
            mock_db_session.query.return_value.filter.return_value.first.side_effect = [
                None,  # Event not found
                intent,  # Booking intent found
            ]

            result = StripeWebhooksService.process_event(mock_db_session, event)

            assert result.stripe_event_id == "evt_new"
            # Verify intent updated
            assert intent.status == "AUTHORIZED"

    def test_process_event_canceled(self, mock_db_session):
        """Test processing payment_intent.canceled."""
        event = MagicMock()
        event.id = "evt_cancel"
        event.type = "payment_intent.canceled"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {"metadata": {"booking_intent_id": str(uuid.uuid4())}}

        intent = BookingIntent(status="AUTHORIZED")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert intent.status == "CANCELLED"

    def test_process_event_failed(self, mock_db_session):
        """Test processing payment_intent.payment_failed."""
        event = MagicMock()
        event.id = "evt_fail"
        event.type = "payment_intent.payment_failed"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {"metadata": {"booking_intent_id": str(uuid.uuid4())}}

        intent = BookingIntent(status="INIT")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert intent.status == "FAILED"
        assert intent.last_error["type"] == "payment_failed"

    def test_process_event_error_handling(self, mock_db_session):
        """Test error handling during processing."""
        event = MagicMock(id="evt_error")
        # Force an error
        event.to_dict.side_effect = Exception("Processing Error")

        mock_db_session.query.return_value.filter.return_value.first.return_value = None

        # Should catch exception and log it in stripe_event
        # But wait, to_dict is called before add.
        # Let's fail during _handle_event logic inside try/except block
        event.to_dict.side_effect = None
        event.to_dict.return_value = {}
        event.type = "unknown.type"

        # Mock add so we can inspect the object
        added_event = None

        def side_effect_add(obj):
            nonlocal added_event
            added_event = obj

        mock_db_session.add.side_effect = side_effect_add

        # Patch _handle_event to raise exception
        with patch(
            "src.services.stripe_webhooks_service.StripeWebhooksService._handle_event",
            side_effect=Exception("Handler Error"),
        ):
            result = StripeWebhooksService.process_event(mock_db_session, event)

            assert result.processing_error["error"] == "Handler Error"

    def test_subscription_created_sets_premium(self, mock_db_session):
        """Test customer.subscription.created sets user to PREMIUM."""
        event = MagicMock()
        event.id = "evt_sub_created"
        event.type = "customer.subscription.created"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {
            "customer": "cus_123",
            "id": "sub_123",
            "current_period_end": 1735689600,
        }

        user = User(id=uuid.uuid4(), plan="FREE", stripe_customer_id="cus_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert user.plan == "PREMIUM"
        assert user.stripe_subscription_id == "sub_123"

    def test_subscription_deleted_clears(self, mock_db_session):
        """Test customer.subscription.deleted clears subscription."""
        event = MagicMock()
        event.id = "evt_sub_deleted"
        event.type = "customer.subscription.deleted"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {"customer": "cus_123", "id": "sub_123"}

        user = User(
            id=uuid.uuid4(),
            plan="PREMIUM",
            stripe_customer_id="cus_123",
            stripe_subscription_id="sub_123",
        )
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert user.plan == "FREE"
        assert user.stripe_subscription_id is None

    def test_subscription_updated_cancellation(self, mock_db_session):
        """Test subscription.updated with canceled status."""
        event = MagicMock()
        event.id = "evt_sub_updated"
        event.type = "customer.subscription.updated"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {
            "customer": "cus_123",
            "status": "canceled",
            "current_period_end": 1735689600,
        }

        user = User(
            id=uuid.uuid4(),
            plan="PREMIUM",
            stripe_customer_id="cus_123",
            stripe_subscription_id="sub_123",
        )
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert user.plan == "FREE"
        assert user.stripe_subscription_id is None

    def test_invoice_payment_succeeded(self, mock_db_session):
        """Test invoice.payment_succeeded updates plan."""
        event = MagicMock()
        event.id = "evt_invoice"
        event.type = "invoice.payment_succeeded"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {
            "customer": "cus_123",
            "lines": {"data": [{"period": {"end": 1735689600}}]},
        }

        user = User(id=uuid.uuid4(), plan="FREE", stripe_customer_id="cus_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, user]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert user.plan == "PREMIUM"

    def test_charge_refunded_webhook(self, mock_db_session):
        """Test charge.refunded updates booking intent."""
        event = MagicMock()
        event.id = "evt_refund"
        event.type = "charge.refunded"
        event.livemode = False
        event.to_dict.return_value = {}
        event.data.object = {"id": "ch_123"}

        intent = BookingIntent(status="CAPTURED", stripe_charge_id="ch_123")
        mock_db_session.query.return_value.filter.return_value.first.side_effect = [None, intent]

        StripeWebhooksService.process_event(mock_db_session, event)
        assert intent.status == "REFUNDED"
