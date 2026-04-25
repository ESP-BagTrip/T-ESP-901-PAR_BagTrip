"""Unit tests for the zombie PaymentIntents cleanup job."""

import uuid
from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock, patch

import stripe

from src.jobs.zombie_payment_intents_job import cancel_zombie_intents
from src.models.booking_intent import BookingIntent


def _intent(**kw) -> BookingIntent:
    defaults = {
        "id": uuid.uuid4(),
        "user_id": uuid.uuid4(),
        "trip_id": uuid.uuid4(),
        "type": "flight",
        "status": "AUTHORIZED",
        "amount": 100,
        "currency": "EUR",
        "stripe_payment_intent_id": "pi_zombie_x",
        "created_at": datetime.now(UTC) - timedelta(days=7),
    }
    defaults.update(kw)
    return BookingIntent(**defaults)


@patch("src.jobs.zombie_payment_intents_job.StripeClient")
@patch("src.jobs.zombie_payment_intents_job.SessionLocal")
def test_cancels_old_authorized_intents_with_idempotency(mock_session_local, mock_client):
    """Stale AUTHORIZED → cancelled locally + Stripe call with idempotency key."""
    intent = _intent()
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.all.return_value = [intent]
    mock_session_local.return_value = mock_db

    cancelled = cancel_zombie_intents()

    assert cancelled == 1
    assert intent.status == "CANCELLED"
    assert intent.last_error["reason"] == "zombie_cleanup"
    kwargs = mock_client.cancel_payment_intent.call_args.kwargs
    assert kwargs["idempotency_key"].startswith("zombie-cleanup-")
    mock_db.commit.assert_called_once()


@patch("src.jobs.zombie_payment_intents_job.StripeClient")
@patch("src.jobs.zombie_payment_intents_job.SessionLocal")
def test_continues_when_stripe_cancel_fails(mock_session_local, mock_client):
    """Stripe error during cancel must not abort the local status update."""
    intent = _intent()
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.all.return_value = [intent]
    mock_session_local.return_value = mock_db
    mock_client.cancel_payment_intent.side_effect = stripe.StripeError("already canceled")

    cancelled = cancel_zombie_intents()

    # Local state moves on even if Stripe errored — otherwise the row stays
    # zombified forever.
    assert cancelled == 1
    assert intent.status == "CANCELLED"


@patch("src.jobs.zombie_payment_intents_job.SessionLocal")
def test_no_stale_intents_returns_zero(mock_session_local):
    mock_db = MagicMock()
    mock_db.query.return_value.filter.return_value.all.return_value = []
    mock_session_local.return_value = mock_db

    assert cancel_zombie_intents() == 0
