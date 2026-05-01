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

import contextlib
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
    # Native PaymentSheet flow (mobile — no browser)
    # ------------------------------------------------------------------

    # PaymentIntent statuses where the client_secret can still drive the
    # mobile PaymentSheet. Anything else (canceled, succeeded with sub
    # still incomplete, processing, …) means the existing subscription
    # is unusable and must be replaced.
    _RECOVERABLE_PI_STATUSES = frozenset(
        {
            "requires_payment_method",
            "requires_confirmation",
            "requires_action",
        }
    )

    @staticmethod
    def start_subscription(db: Session, user: User) -> dict:
        """Start a Premium subscription for the native Flutter PaymentSheet.

        First tries to *reuse* any existing `incomplete` subscription whose
        PaymentIntent is still in a confirmable state — without this, a
        user who closes the app mid-payment hits Stripe's idempotency
        cache on the next try and gets back the *same* trio while the
        PaymentIntent has since been canceled, which makes the sheet
        open and close immediately.

        If the existing subscription's PaymentIntent is stuck (canceled
        / processing / etc.), we cancel it and create a fresh one rather
        than fight the cached state.

        Returns the trio the SDK needs (`paymentIntentClientSecret`,
        `ephemeralKey`, `customer`) plus the subscription id so the app
        can correlate the result. The subscription itself is *not*
        marked active until the PaymentIntent confirms — the
        `customer.subscription.created` / `invoice.payment_succeeded`
        webhooks flip `User.plan` server-side, the app just refreshes
        the user once the PaymentSheet returns success.
        """
        _ensure_stripe_configured()

        if PlanService.get_plan(user).value != "FREE":
            raise AppError("ALREADY_PREMIUM", 400, "You are already on a paid plan")

        customer_id = _ensure_customer(user)
        price_id = SubscriptionService._get_premium_price_id()

        try:
            subscription = SubscriptionService._reuse_or_create_subscription(
                customer_id=customer_id,
                price_id=price_id,
                user_id=str(user.id),
            )
            ephemeral_key = StripeClient.create_ephemeral_key(customer_id)
        except stripe.StripeError as exc:
            logger.error(f"Stripe start subscription failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not start subscription") from exc

        # `latest_invoice` was expanded with `payment_intent` so we can
        # pluck the client_secret without a second round-trip.
        invoice = getattr(subscription, "latest_invoice", None)
        payment_intent = getattr(invoice, "payment_intent", None) if invoice else None
        client_secret = getattr(payment_intent, "client_secret", None) if payment_intent else None
        if not client_secret:
            logger.error(
                f"Subscription {subscription.id} has no client_secret on "
                "latest_invoice.payment_intent"
            )
            raise AppError("STRIPE_ERROR", 500, "Subscription missing PaymentIntent")

        return {
            "subscription_id": subscription.id,
            "payment_intent_client_secret": client_secret,
            "ephemeral_key": ephemeral_key.secret,
            "customer": customer_id,
        }

    @staticmethod
    def _reuse_or_create_subscription(
        *, customer_id: str, price_id: str, user_id: str
    ) -> stripe.Subscription:
        """Reuse an in-progress subscription, or create a fresh one.

        Looks for an existing `incomplete` subscription on the customer.
        If its PaymentIntent is still confirmable, it's returned as-is
        (with the invoice + PI re-expanded so callers can read
        `client_secret`). Otherwise the stale subscription is cancelled
        and a new one is created.

        No idempotency key on the create call — the list-and-reuse step
        already dedupes within-session retries, and an idempotency key
        was the cause of the stale-cache bug we're fixing here.
        """
        existing = StripeClient.list_subscriptions(
            customer=customer_id, status="incomplete", limit=1
        )
        if existing.data:
            sub_id = existing.data[0].id
            sub = StripeClient.retrieve_subscription(
                sub_id, expand=["latest_invoice.payment_intent"]
            )
            invoice = getattr(sub, "latest_invoice", None)
            pi = getattr(invoice, "payment_intent", None) if invoice else None
            pi_status = getattr(pi, "status", None) if pi else None
            if pi_status in SubscriptionService._RECOVERABLE_PI_STATUSES:
                logger.info(
                    f"Reusing incomplete subscription {sub_id} (PaymentIntent in {pi_status})"
                )
                return sub
            # Stale subscription — cancel before creating a fresh one so
            # we don't accumulate orphans on the customer.
            logger.info(
                f"Cancelling stale incomplete subscription {sub_id} "
                f"(PaymentIntent in {pi_status!r})"
            )
            with contextlib.suppress(stripe.StripeError):
                StripeClient.cancel_subscription(sub_id)

        return StripeClient.create_subscription(
            customer=customer_id,
            price=price_id,
            metadata={"user_id": user_id},
        )

    @staticmethod
    def start_payment_method_update(db: Session, user: User) -> dict:
        """Start an in-app payment method update via SetupIntent.

        Replaces the Stripe Billing Portal "Change card" flow. The mobile
        SDK opens its PaymentSheet in setup mode, the user attaches a
        new card without leaving the app, and we wire it as the
        subscription's default once the SetupIntent confirms.
        """
        _ensure_stripe_configured()
        customer_id = _ensure_customer(user)

        try:
            setup_intent = StripeClient.create_setup_intent(customer=customer_id)
            ephemeral_key = StripeClient.create_ephemeral_key(customer_id)
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe SetupIntent creation failed for {customer_id}: {exc}",
                exc_info=True,
            )
            raise AppError("STRIPE_ERROR", 500, "Could not start payment method update") from exc

        return {
            "setup_intent_client_secret": setup_intent.client_secret,
            "ephemeral_key": ephemeral_key.secret,
            "customer": customer_id,
        }

    @staticmethod
    def attach_default_payment_method(db: Session, user: User, payment_method_id: str) -> dict:
        """Set `payment_method_id` as the default for the active subscription.

        Called after the in-app SetupIntent succeeds. The subscription's
        `default_payment_method` is updated so future renewals charge the
        new card, and the customer's `invoice_settings.default_payment_method`
        is updated so any one-off charges follow suit.
        """
        _ensure_stripe_configured()
        customer_id = _ensure_customer(user)
        if not user.stripe_subscription_id:
            raise AppError("NO_ACTIVE_SUBSCRIPTION", 400, "No active subscription")

        try:
            # Customer-level default — used for one-off charges and any
            # future subscription created without an explicit
            # `default_payment_method`.
            stripe.Customer.modify(
                customer_id,
                invoice_settings={"default_payment_method": payment_method_id},
            )
            # Subscription-level default — what actually gets charged on
            # the next renewal.
            StripeClient.update_subscription(
                user.stripe_subscription_id,
                idempotency_key=f"sub-{user.id}-pm-{payment_method_id}-v1",
                default_payment_method=payment_method_id,
            )
        except stripe.StripeError as exc:
            logger.error(
                f"Stripe attach default payment method failed: {exc}",
                exc_info=True,
            )
            raise AppError("STRIPE_ERROR", 500, "Could not attach payment method") from exc

        return {"status": "attached"}

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
