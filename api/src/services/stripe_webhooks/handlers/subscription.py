"""Handlers for `customer.subscription.*` events."""

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


def _set_plan_expiry(user, period_end: int | None) -> None:
    if period_end:
        user.plan_expires_at = datetime.fromtimestamp(period_end, tz=UTC)


def handle_subscription_created(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`customer.subscription.created` — user just subscribed to Premium."""
    user = find_user_by_customer(db, event)
    if not user:
        logger.warn(f"subscription.created: user not found for event {event.id}")
        return
    obj = event.data.object
    if user.plan != "ADMIN":
        user.plan = "PREMIUM"
    user.stripe_subscription_id = get_obj_attr(obj, "id")
    _set_plan_expiry(user, get_obj_attr(obj, "current_period_end"))
    db.commit()
    logger.info(f"User {user.id} → PREMIUM (subscription {user.stripe_subscription_id})")


def handle_subscription_updated(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`customer.subscription.updated` — status change, renewal, cancel_at_period_end."""
    user = find_user_by_customer(db, event)
    if not user:
        return
    obj = event.data.object
    status_val = get_obj_attr(obj, "status")
    _set_plan_expiry(user, get_obj_attr(obj, "current_period_end"))
    if status_val in ("canceled", "unpaid", "incomplete_expired"):
        # End of the road — drop them back to FREE. Renewal failures end up
        # here after the dunning grace period expires.
        if user.plan != "ADMIN":
            user.plan = "FREE"
        user.stripe_subscription_id = None
    db.commit()


def handle_subscription_deleted(
    db: Session, event: stripe.Event, stripe_event: StripeEvent
) -> None:
    """`customer.subscription.deleted` — Stripe purged the subscription."""
    user = find_user_by_customer(db, event)
    if not user:
        logger.warn(f"subscription.deleted: user not found for event {event.id}")
        return
    if user.plan != "ADMIN":
        user.plan = "FREE"
    user.stripe_subscription_id = None
    user.plan_expires_at = None
    db.commit()
    logger.info(f"User {user.id} → FREE (subscription deleted)")
