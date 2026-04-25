"""Service for Stripe subscription management.

Covers the full Premium lifecycle from the API layer:
  - `create_checkout_session` — initial paywall (Stripe Checkout).
  - `create_portal_session` — self-service for everything else (CB, invoices).
  - `cancel_subscription` / `reactivate_subscription` — explicit API hooks
    so the mobile UI doesn't have to bounce through the portal for the
    common "cancel my plan" path.
  - `get_subscription_details` / `list_invoices` — read-side for the
    "Manage my subscription" screen.

Relies on Stripe webhooks to keep `User.plan`, `stripe_subscription_id` and
`plan_expires_at` in sync — service writes are best-effort enrichments and
should not be the sole source of truth.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

import stripe
from sqlalchemy.orm import Session

from src.config.env import settings
from src.integrations.stripe.client import StripeClient
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.errors import AppError
from src.utils.logger import logger


def _ensure_stripe_configured() -> None:
    if not settings.STRIPE_SECRET_KEY:
        raise AppError("STRIPE_NOT_CONFIGURED", 500, "Stripe not configured")


def _ensure_customer(user: User) -> str:
    if not user.stripe_customer_id:
        raise AppError("STRIPE_CUSTOMER_MISSING", 500, "Stripe customer not found")
    return user.stripe_customer_id


class SubscriptionService:
    """Handles the Premium subscription lifecycle."""

    # ------------------------------------------------------------------
    # Checkout / Portal
    # ------------------------------------------------------------------

    @staticmethod
    def _get_premium_price_id() -> str:
        """Return the Stripe Price ID for Premium subscription."""
        from src.services.stripe_products_service import STRIPE_PRODUCT_IDS

        product_id = STRIPE_PRODUCT_IDS.get("premium_subscription")
        if not product_id:
            raise AppError("STRIPE_NOT_CONFIGURED", 500, "Premium product not configured in Stripe")
        return product_id

    @staticmethod
    def create_checkout_session(db: Session, user: User) -> dict:
        """Create a Stripe Checkout Session for Premium subscription."""
        _ensure_stripe_configured()

        if PlanService.get_plan(user).value != "FREE":
            raise AppError("ALREADY_PREMIUM", 400, "You are already on a paid plan")

        customer_id = _ensure_customer(user)

        try:
            session = stripe.checkout.Session.create(
                customer=customer_id,
                mode="subscription",
                line_items=[{"price": SubscriptionService._get_premium_price_id(), "quantity": 1}],
                success_url=settings.STRIPE_SUCCESS_URL,
                cancel_url=settings.STRIPE_CANCEL_URL,
                metadata={"user_id": str(user.id)},
            )
            return {"url": session.url}
        except stripe.StripeError as exc:
            logger.error(f"Stripe checkout error: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not start checkout") from exc

    @staticmethod
    def create_portal_session(db: Session, user: User) -> dict:
        """Create a Stripe Billing Portal session — self-service for everything."""
        _ensure_stripe_configured()
        customer_id = _ensure_customer(user)

        try:
            session = StripeClient.create_billing_portal_session(
                customer_id=customer_id,
                return_url=settings.STRIPE_PORTAL_RETURN_URL,
            )
            return {"url": session.url}
        except stripe.StripeError as exc:
            logger.error(f"Stripe portal error: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not open billing portal") from exc

    # ------------------------------------------------------------------
    # Status & details
    # ------------------------------------------------------------------

    @staticmethod
    def get_status(db: Session, user: User) -> dict:
        """Lightweight plan info — backwards compat with the existing route."""
        plan_info = PlanService.get_plan_info(db, user)
        return {
            **plan_info,
            "stripe_subscription_id": user.stripe_subscription_id,
            "plan_expires_at": user.plan_expires_at.isoformat() if user.plan_expires_at else None,
        }

    @staticmethod
    def get_subscription_details(db: Session, user: User) -> dict:
        """Detailed view for the "Manage my subscription" screen.

        Combines local plan info with live Stripe state (renewal date, card
        last4, cancel_at_period_end). Falls back gracefully when Stripe is
        unreachable so the UI can still show *something*.
        """
        base = SubscriptionService.get_status(db, user)
        details: dict[str, Any] = {
            **base,
            "cancel_at_period_end": False,
            "current_period_end": None,
            "payment_method": None,
        }

        if not (settings.STRIPE_SECRET_KEY and user.stripe_subscription_id):
            return details

        try:
            sub = StripeClient.retrieve_subscription(user.stripe_subscription_id)
        except stripe.StripeError as exc:
            logger.warn(f"Could not retrieve subscription {user.stripe_subscription_id}: {exc}")
            return details

        details["cancel_at_period_end"] = bool(getattr(sub, "cancel_at_period_end", False))
        period_end = getattr(sub, "current_period_end", None)
        if period_end:
            details["current_period_end"] = datetime.fromtimestamp(period_end, tz=UTC).isoformat()

        # Default payment method preview — last4 / brand, no PCI footprint.
        default_pm_id = getattr(sub, "default_payment_method", None)
        if default_pm_id:
            try:
                pm = StripeClient.retrieve_payment_method(default_pm_id)
                card = getattr(pm, "card", None)
                if card:
                    details["payment_method"] = {
                        "brand": getattr(card, "brand", None),
                        "last4": getattr(card, "last4", None),
                        "exp_month": getattr(card, "exp_month", None),
                        "exp_year": getattr(card, "exp_year", None),
                    }
            except stripe.StripeError as exc:
                logger.warn(f"Could not retrieve payment method {default_pm_id}: {exc}")

        return details

    # ------------------------------------------------------------------
    # Cancel / Reactivate
    # ------------------------------------------------------------------

    @staticmethod
    def cancel_subscription(db: Session, user: User) -> dict:
        """Cancel at period end — keeps Premium until `current_period_end`."""
        _ensure_stripe_configured()
        if not user.stripe_subscription_id:
            raise AppError("NO_ACTIVE_SUBSCRIPTION", 400, "No active subscription to cancel")

        try:
            sub = StripeClient.update_subscription(
                user.stripe_subscription_id,
                idempotency_key=f"sub-{user.id}-cancel-v1",
                cancel_at_period_end=True,
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe cancel failed for sub {user.stripe_subscription_id}: {exc}",
                exc_info=True,
            )
            raise AppError("STRIPE_ERROR", 500, "Could not cancel subscription") from exc

        period_end = getattr(sub, "current_period_end", None)
        return {
            "status": "scheduled_for_cancellation",
            "cancel_at_period_end": True,
            "current_period_end": (
                datetime.fromtimestamp(period_end, tz=UTC).isoformat() if period_end else None
            ),
        }

    @staticmethod
    def reactivate_subscription(db: Session, user: User) -> dict:
        """Undo a `cancel_at_period_end` while still in the current period."""
        _ensure_stripe_configured()
        if not user.stripe_subscription_id:
            raise AppError("NO_ACTIVE_SUBSCRIPTION", 400, "No subscription to reactivate")

        try:
            sub = StripeClient.update_subscription(
                user.stripe_subscription_id,
                idempotency_key=f"sub-{user.id}-reactivate-v1",
                cancel_at_period_end=False,
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe reactivate failed for sub {user.stripe_subscription_id}: {exc}",
                exc_info=True,
            )
            raise AppError("STRIPE_ERROR", 500, "Could not reactivate subscription") from exc

        period_end = getattr(sub, "current_period_end", None)
        return {
            "status": "active",
            "cancel_at_period_end": False,
            "current_period_end": (
                datetime.fromtimestamp(period_end, tz=UTC).isoformat() if period_end else None
            ),
        }

    # ------------------------------------------------------------------
    # Invoices
    # ------------------------------------------------------------------

    @staticmethod
    def list_invoices(db: Session, user: User, limit: int = 12) -> list[dict]:
        """Return the user's recent invoices (most recent first)."""
        _ensure_stripe_configured()
        if not user.stripe_customer_id:
            return []

        try:
            invoices = StripeClient.list_invoices(user.stripe_customer_id, limit=limit)
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe invoice list failed for customer {user.stripe_customer_id}: {exc}",
                exc_info=True,
            )
            raise AppError("STRIPE_ERROR", 500, "Could not list invoices") from exc

        result: list[dict] = []
        for inv in invoices.data:
            created = getattr(inv, "created", None)
            result.append(
                {
                    "id": getattr(inv, "id", None),
                    "number": getattr(inv, "number", None),
                    "status": getattr(inv, "status", None),
                    "amount_paid": getattr(inv, "amount_paid", None),
                    "currency": getattr(inv, "currency", None),
                    "created": (
                        datetime.fromtimestamp(created, tz=UTC).isoformat() if created else None
                    ),
                    "hosted_invoice_url": getattr(inv, "hosted_invoice_url", None),
                    "invoice_pdf": getattr(inv, "invoice_pdf", None),
                }
            )
        return result
