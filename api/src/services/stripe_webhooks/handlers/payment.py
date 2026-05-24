"""Handlers for `payment_intent.*` events."""

from __future__ import annotations

import stripe
from sqlalchemy.orm import Session

from src.enums import BookingIntentStatus
from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.utils.logger import logger


def _load_intent(db: Session, stripe_event: StripeEvent) -> BookingIntent | None:
    if not stripe_event.booking_intent_id:
        return None
    return (
        db.query(BookingIntent).filter(BookingIntent.id == stripe_event.booking_intent_id).first()
    )


def handle_amount_capturable_updated(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`payment_intent.amount_capturable_updated` — funds authorized, awaiting capture."""
    intent = _load_intent(db, stripe_event)
    if intent and intent.status == BookingIntentStatus.INIT:
        intent.status = BookingIntentStatus.AUTHORIZED
        db.commit()


def handle_payment_intent_succeeded(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`payment_intent.succeeded` — capture confirmed by Stripe.

    For our manual-capture flow this fires after `capture_payment` returns,
    so the local status is usually already CAPTURED. Treat the webhook as a
    reconciliation safety net (e.g. capture happened on the Stripe dashboard
    or via a retried webhook) — only flip the status if we missed the local
    update.
    """
    intent = _load_intent(db, stripe_event)
    if not intent:
        return
    if intent.status in (BookingIntentStatus.BOOKED, BookingIntentStatus.AUTHORIZED):
        intent.status = BookingIntentStatus.CAPTURED
        # Backfill charge id if we somehow missed it during direct capture.
        obj = event.data.object
        latest_charge = (
            obj.get("latest_charge")
            if isinstance(obj, dict)
            else getattr(obj, "latest_charge", None)
        )
        if latest_charge and not intent.stripe_charge_id:
            intent.stripe_charge_id = latest_charge
        db.commit()


def handle_payment_intent_canceled(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`payment_intent.canceled` — Stripe canceled the PI (manual cancel or 7-day timeout)."""
    intent = _load_intent(db, stripe_event)
    if intent and intent.status != BookingIntentStatus.CAPTURED:
        intent.status = BookingIntentStatus.CANCELLED
        db.commit()


def handle_payment_intent_failed(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`payment_intent.payment_failed` — capture or confirmation failed."""
    intent = _load_intent(db, stripe_event)
    if intent:
        intent.status = BookingIntentStatus.FAILED
        intent.last_error = {"type": "payment_failed", "event_id": event.id}
        db.commit()
        logger.warn(f"Payment failed for booking_intent {intent.id} (event {event.id})")
