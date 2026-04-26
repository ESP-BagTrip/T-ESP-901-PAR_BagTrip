"""Stripe webhook dispatcher.

Idempotency
-----------
Every event is keyed by `stripe_event_id` with a unique constraint at the DB
layer. Duplicate deliveries (Stripe retries on non-2xx, replays via the
dashboard) short-circuit by returning the existing `StripeEvent` row.

Adding a new event
------------------
1. Implement the handler in `handlers/<domain>.py`.
2. Add an entry to `_DISPATCH` below.
That's it — no other changes needed.
"""

from __future__ import annotations

import contextlib
from collections.abc import Callable
from datetime import UTC, datetime
from uuid import UUID

import stripe
from sqlalchemy.orm import Session

from src.models.stripe_event import StripeEvent
from src.services.stripe_webhooks.handlers import charge, invoice, payment, subscription
from src.utils.logger import logger

_Handler = Callable[[Session, stripe.Event, StripeEvent], None]

# Single source of truth for "what events we handle". Keep alphabetical so
# diff-readers can scan it quickly.
_DISPATCH: dict[str, _Handler] = {
    "charge.dispute.created": charge.handle_charge_dispute_created,
    "charge.refunded": charge.handle_charge_refunded,
    "customer.subscription.created": subscription.handle_subscription_created,
    "customer.subscription.deleted": subscription.handle_subscription_deleted,
    "customer.subscription.updated": subscription.handle_subscription_updated,
    "invoice.payment_failed": invoice.handle_invoice_payment_failed,
    "invoice.payment_succeeded": invoice.handle_invoice_payment_succeeded,
    "payment_intent.amount_capturable_updated": payment.handle_amount_capturable_updated,
    "payment_intent.canceled": payment.handle_payment_intent_canceled,
    "payment_intent.payment_failed": payment.handle_payment_intent_failed,
    "payment_intent.succeeded": payment.handle_payment_intent_succeeded,
}


class StripeWebhooksService:
    """Service pour le traitement des événements Stripe."""

    @staticmethod
    def process_event(
        db: Session,
        event: stripe.Event,
    ) -> StripeEvent:
        """Process a Stripe event idempotently.

        Persists the event, runs the matching handler (if any), and records
        any handler exception in `processing_error` so the row is preserved
        for debugging without crashing the webhook endpoint.
        """
        existing = db.query(StripeEvent).filter(StripeEvent.stripe_event_id == event.id).first()
        if existing:
            return existing

        stripe_event = StripeEvent(
            stripe_event_id=event.id,
            type=event.type,
            livemode=event.livemode,
            payload=event.to_dict(),
        )

        # Link to a BookingIntent when the event metadata identifies one.
        if event.type.startswith("payment_intent."):
            metadata = StripeWebhooksService._extract_metadata(event)
            booking_intent_id_str = metadata.get("booking_intent_id")
            if booking_intent_id_str:
                with contextlib.suppress(ValueError):
                    stripe_event.booking_intent_id = UUID(booking_intent_id_str)

        db.add(stripe_event)
        db.flush()

        handler = _DISPATCH.get(event.type)
        if handler is not None:
            try:
                handler(db, event, stripe_event)
                stripe_event.processed_at = datetime.now(UTC)
            except Exception as exc:
                # Persist the error so the row remains useful for debugging,
                # but don't propagate — Stripe retries non-2xx and a handler
                # bug shouldn't keep retrying forever.
                logger.error(
                    f"Webhook handler {event.type} failed: {exc}",
                    exc_info=True,
                )
                stripe_event.processing_error = {
                    "error": str(exc),
                    "type": type(exc).__name__,
                }
        else:
            # Unknown event type — record but no-op. Keeps the audit log full
            # without polluting logs with WARN for events we deliberately
            # don't handle (e.g. `customer.created`, `payout.*`).
            stripe_event.processed_at = datetime.now(UTC)

        db.commit()
        db.refresh(stripe_event)
        return stripe_event

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    @staticmethod
    def _extract_metadata(event: stripe.Event) -> dict:
        # Stripe's `StripeObject` subclasses dict, so this `.get()` works for
        # both the signed-webhook path and the dev escape hatch where we
        # construct events from raw JSON.
        obj = event.data.object
        return obj.get("metadata") or {}
