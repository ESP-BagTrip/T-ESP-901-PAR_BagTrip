"""Shared helpers for webhook handlers."""

from __future__ import annotations

from typing import Any

import stripe
from sqlalchemy.orm import Session

from src.models.user import User


def get_obj_attr(obj: Any, key: str, default: Any = None) -> Any:
    """Read an attribute from a Stripe event payload regardless of shape.

    Stripe events come through as dicts when constructed from raw JSON (dev
    escape hatch) or as `StripeObject` instances when constructed via signed
    webhook verification. Treat both uniformly.
    """
    if isinstance(obj, dict):
        return obj.get(key, default)
    return getattr(obj, key, default)


def find_user_by_customer(db: Session, event: stripe.Event) -> User | None:
    """Locate the local `User` for a Stripe event whose object has a `customer` field."""
    obj = event.data.object
    customer_id = get_obj_attr(obj, "customer")
    if not customer_id:
        return None
    return db.query(User).filter(User.stripe_customer_id == customer_id).first()
