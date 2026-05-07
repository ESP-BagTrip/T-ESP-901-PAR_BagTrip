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

import uuid
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


def _resolve_customer_id(db: Session, user: User) -> str:
    """Return a Stripe customer_id known to exist on the current account.

    `User.stripe_customer_id` can go stale in two situations we hit in the
    wild:
      - someone deletes the customer in the Stripe dashboard;
      - the secret key was switched to a different Stripe workspace
        (common in dev when juggling test accounts).

    Both surface as `resource_missing` on the next mutating call. Without
    recovery, every subscribe / payment-method-update for that user is
    permanently broken until an operator hand-edits the DB. So we
    eagerly verify the customer exists and, if it doesn't, recreate it
    and persist the new id. Costs one extra `Customer.retrieve` round-trip
    per `/start` — cheap insurance.
    """
    customer_id = _ensure_customer(user)
    try:
        StripeClient.retrieve_customer(customer_id)
        return customer_id
    except stripe.InvalidRequestError as exc:
        if getattr(exc, "code", None) != "resource_missing":
            raise

    logger.warn(
        f"User {user.id} stripe_customer_id '{customer_id}' is missing on "
        "the current Stripe account — recreating."
    )
    # Idempotency key includes a uuid so a retry isn't short-circuited by
    # the now-deleted customer's cached response.
    new_customer = StripeClient.create_customer(
        email=user.email,
        name=user.full_name,
        idempotency_key=f"user-{user.id}-customer-recreate-{uuid.uuid4().hex[:8]}",
    )
    user.stripe_customer_id = new_customer.id
    db.commit()
    db.refresh(user)
    return new_customer.id


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

    @staticmethod
    def start_subscription(db: Session, user: User) -> dict:
        """Bootstrap the native PaymentSheet — no Stripe write yet.

        With the deferred `IntentConfiguration` flow, the mobile SDK
        only needs the customer's ephemeral key and the price (amount +
        currency) to render the PaymentSheet. The actual `Subscription`
        is created in `confirm_subscription` once the user has actually
        chosen a payment method and tapped Pay — that's how we avoid
        the "incomplete subscription orphans" the upfront-creation
        pattern leaves behind when users dismiss without paying, and
        how the sheet opens instantly (no Stripe round-trip on the way
        in).
        """
        _ensure_stripe_configured()

        if PlanService.get_plan(user).value != "FREE":
            raise AppError("ALREADY_PREMIUM", 400, "You are already on a paid plan")

        try:
            customer_id = _resolve_customer_id(db, user)
        except stripe.StripeError as exc:
            logger.error(f"Customer resolution failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not resolve customer") from exc

        price_id = SubscriptionService._get_premium_price_id()

        try:
            # Resolve the live price so a backend-side change to
            # `unit_amount` / `currency` flows automatically into the
            # mobile sheet without an app update.
            price = stripe.Price.retrieve(price_id)
            ephemeral_key = StripeClient.create_ephemeral_key(customer_id)
        except stripe.StripeError as exc:
            logger.error(f"Stripe start bootstrap failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not start subscription") from exc

        return {
            "customer": customer_id,
            "ephemeral_key": ephemeral_key.secret,
            "amount": price.unit_amount,
            "currency": price.currency,
        }

    @staticmethod
    def confirm_subscription(db: Session, user: User, payment_method_id: str) -> dict:
        """Create the `Subscription` with the just-chosen payment method.

        Called by the Flutter `PaymentSheet`'s `confirmHandler` after
        the user has tapped Pay. The Subscription is created in
        `default_incomplete` so Stripe returns a confirmable
        `PaymentIntent` whose `client_secret` we hand back to the SDK
        — the SDK finalises the payment in-sheet (3DS / SCA in line).

        Idempotency keys on `(user_id, payment_method_id)` so a
        network retry of the confirm POST returns the same Subscription
        instead of creating a duplicate.
        """
        _ensure_stripe_configured()

        if PlanService.get_plan(user).value != "FREE":
            raise AppError("ALREADY_PREMIUM", 400, "You are already on a paid plan")

        try:
            customer_id = _resolve_customer_id(db, user)
        except stripe.StripeError as exc:
            logger.error(f"Customer resolution failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not resolve customer") from exc

        price_id = SubscriptionService._get_premium_price_id()

        try:
            # Attach the just-collected PaymentMethod to the customer
            # *before* using it as the subscription default. In deferred
            # IntentConfiguration the SDK hands us a PM that isn't yet
            # bound to the customer; Stripe rejects
            # `default_payment_method` until the attach lands.
            # Idempotency keys on (user, pm) so a network retry of the
            # confirm POST short-circuits the second attach call.
            StripeClient.attach_payment_method(
                payment_method_id,
                customer_id,
                idempotency_key=f"pm-attach-{user.id}-{payment_method_id}-v1",
            )
            subscription = StripeClient.create_subscription(
                customer=customer_id,
                price=price_id,
                idempotency_key=f"sub-{user.id}-confirm-{payment_method_id}-v1",
                default_payment_method=payment_method_id,
                metadata={"user_id": str(user.id)},
            )
        except stripe.StripeError as exc:
            logger.error(f"Stripe confirm subscription failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not confirm subscription") from exc

        # `latest_invoice` is expanded with `payment_intent` (see
        # `StripeClient.create_subscription`) so we can read the
        # client_secret in a single round-trip.
        invoice = getattr(subscription, "latest_invoice", None)
        payment_intent = getattr(invoice, "payment_intent", None) if invoice else None
        client_secret = getattr(payment_intent, "client_secret", None) if payment_intent else None
        if not client_secret:
            logger.error(
                f"Subscription {subscription.id} has no client_secret on "
                "latest_invoice.payment_intent"
            )
            raise AppError("STRIPE_ERROR", 500, "Subscription missing PaymentIntent")

        # Persist the subscription id on the user *now* — the
        # `customer.subscription.created` webhook is the canonical source
        # of truth for `plan`, but it can lag (or never arrive in local
        # dev without `stripe listen`). Storing the id here means
        # `get_subscription_details` can self-heal on read by querying
        # Stripe directly when the webhook is delayed. Idempotent: the
        # webhook will write the same value when it lands.
        if user.stripe_subscription_id != subscription.id:
            user.stripe_subscription_id = subscription.id
            db.commit()
            db.refresh(user)

        return {
            "subscription_id": subscription.id,
            "client_secret": client_secret,
        }

    @staticmethod
    def start_payment_method_update(db: Session, user: User) -> dict:
        """Start an in-app payment method update via SetupIntent.

        Replaces the Stripe Billing Portal "Change card" flow. The mobile
        SDK opens its PaymentSheet in setup mode, the user attaches a
        new card without leaving the app, and we wire it as the
        subscription's default once the SetupIntent confirms.
        """
        _ensure_stripe_configured()
        try:
            customer_id = _resolve_customer_id(db, user)
        except stripe.StripeError as exc:
            logger.error(f"Customer resolution failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not resolve customer") from exc

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
        if not user.stripe_subscription_id:
            raise AppError("NO_ACTIVE_SUBSCRIPTION", 400, "No active subscription")
        try:
            customer_id = _resolve_customer_id(db, user)
        except stripe.StripeError as exc:
            logger.error(f"Customer resolution failed: {exc}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, "Could not resolve customer") from exc

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
    async def get_status(db: Session, user: User) -> dict:
        """Lightweight plan info — backwards compat with the existing route.

        ``get_plan_info`` reconciles against Stripe before returning, so
        the caller never sees a stale FREE for a freshly-subscribed user.
        """
        plan_info = await PlanService.get_plan_info(db, user)
        return {
            **plan_info,
            "stripe_subscription_id": user.stripe_subscription_id,
            "plan_expires_at": user.plan_expires_at.isoformat() if user.plan_expires_at else None,
        }

    @staticmethod
    async def get_subscription_details(db: Session, user: User) -> dict:
        """Detailed view for the "Manage my subscription" screen.

        Combines local plan info with live Stripe state (renewal date,
        card last4, ``cancel_at_period_end``). The plan field is taken
        from ``PlanService.get_plan_info``, which itself reconciles
        against Stripe — no need for a duplicate self-heal here.
        """
        base = await SubscriptionService.get_status(db, user)
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
