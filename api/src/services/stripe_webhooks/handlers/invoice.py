"""Handlers for `invoice.*` events."""

from __future__ import annotations

from datetime import UTC, datetime

import stripe
from sqlalchemy.orm import Session

from src.models.stripe_event import StripeEvent
from src.services.stripe_webhooks.handlers._helpers import (
    find_user_by_customer,
    get_obj_attr,
)
from src.utils.logger import logger


def handle_invoice_payment_succeeded(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`invoice.payment_succeeded` — billing cycle paid, refresh `plan_expires_at`."""
    user = find_user_by_customer(db, event)
    if not user:
        return
    obj = event.data.object
    lines = get_obj_attr(obj, "lines", {})
    data = get_obj_attr(lines, "data", []) or []
    for line in data:
        period = get_obj_attr(line, "period", {})
        end = get_obj_attr(period, "end")
        if end:
            user.plan_expires_at = datetime.fromtimestamp(end, tz=UTC)
            break
    if user.plan != "ADMIN":
        user.plan = "PREMIUM"
    db.commit()


def handle_invoice_payment_failed(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`invoice.payment_failed` — billing failed (declined card, expired CB...).

    We don't downgrade immediately — Stripe runs its own dunning retries. If
    those exhaust, `customer.subscription.updated` fires with `status=unpaid`
    and the subscription handler drops them to FREE. This handler just records
    the failure prominently in logs so the team notices the spike.
    """
    user = find_user_by_customer(db, event)
    if not user:
        return
    obj = event.data.object
    invoice_id = get_obj_attr(obj, "id", "?")
    attempt = get_obj_attr(obj, "attempt_count", "?")
    logger.warn(
        f"invoice.payment_failed for user {user.id} (invoice {invoice_id}, attempt {attempt})"
    )
