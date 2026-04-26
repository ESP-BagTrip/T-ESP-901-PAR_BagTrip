"""Handlers for `charge.*` events."""

from __future__ import annotations

import stripe
from sqlalchemy.orm import Session

from src.enums import BookingIntentStatus
from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.services.stripe_webhooks.handlers._helpers import get_obj_attr
from src.utils.logger import logger


def handle_charge_refunded(db: Session, event: stripe.Event, stripe_event: StripeEvent) -> None:
    """`charge.refunded` — sync local status when refund is fully processed.

    Fires for refunds initiated via the API AND via the Stripe dashboard, so
    a manual refund in Stripe doesn't leave the local row stuck on CAPTURED.
    Only marks REFUNDED when the charge is fully refunded — partial refunds
    keep CAPTURED so the user can still issue further partial refunds.
    """
    obj = event.data.object
    charge_id = get_obj_attr(obj, "id")
    if not charge_id:
        return

    intent = db.query(BookingIntent).filter(BookingIntent.stripe_charge_id == charge_id).first()
    if not intent:
        return

    fully_refunded = bool(get_obj_attr(obj, "refunded", False))
    amount = int(get_obj_attr(obj, "amount", 0) or 0)
    amount_refunded = int(get_obj_attr(obj, "amount_refunded", 0) or 0)
    if not fully_refunded and amount > 0:
        fully_refunded = amount_refunded >= amount

    if fully_refunded and intent.status == BookingIntentStatus.CAPTURED:
        intent.status = BookingIntentStatus.REFUNDED
        db.commit()


def handle_charge_dispute_created(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`charge.dispute.created` — chargeback opened.

    No automatic state change — disputes need human review via the Stripe
    dashboard. We log loudly so an admin notices, and keep the full event
    payload in the StripeEvent table for audit / runbook reference.
    """
    obj = event.data.object
    charge_id = get_obj_attr(obj, "charge")
    amount = get_obj_attr(obj, "amount")
    reason = get_obj_attr(obj, "reason")
    logger.error(
        f"charge.dispute.created — charge={charge_id} amount={amount} reason={reason} "
        f"(event {event.id}). Action required: review on Stripe dashboard."
    )
