"""Handlers for `charge.*` events."""

from __future__ import annotations

import stripe
from sqlalchemy.orm import Session

from src.enums import BookingIntentStatus
from src.models.booking_intent import BookingIntent
from src.models.stripe_event import StripeEvent
from src.services.stripe_webhooks.handlers._helpers import find_user_by_customer, get_obj_attr
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

    Decision (SMP-327): a chargeback revokes Premium immediately. The user is
    dropped back to FREE as soon as the dispute is opened. A dispute we later
    win needs a manual re-upgrade — accepted trade-off for keeping this simple.
    We still log loudly and keep the full payload in StripeEvent for audit.
    """
    obj = event.data.object
    charge_id = get_obj_attr(obj, "charge")
    amount = get_obj_attr(obj, "amount")
    reason = get_obj_attr(obj, "reason")
    logger.error(
        f"charge.dispute.created — charge={charge_id} amount={amount} reason={reason} "
        f"(event {event.id}). Downgrading to FREE; review on Stripe dashboard."
    )

    user = find_user_by_customer(db, event)
    if not user:
        logger.warn(f"charge.dispute.created: user not found for event {event.id}")
        return
    if user.plan != "ADMIN":
        user.plan = "FREE"
        user.plan_expires_at = None
        db.commit()
        logger.info(f"User {user.id} → FREE (chargeback dispute opened)")
