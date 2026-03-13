"""Service for Stripe subscription management (checkout, portal, status)."""

import stripe
from sqlalchemy.orm import Session

from src.config.env import settings
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.errors import AppError
from src.utils.logger import logger


class SubscriptionService:
    """Handles Stripe Checkout and Billing Portal for Premium subscriptions."""

    @staticmethod
    def _get_premium_price_id() -> str:
        """Return the Stripe Price ID for Premium subscription."""
        from src.services.stripe_products_service import STRIPE_PRODUCT_IDS

        product_id = STRIPE_PRODUCT_IDS.get("premium_subscription")
        if not product_id:
            raise AppError("STRIPE_NOT_CONFIGURED", 500, "Premium product not configured in Stripe")
        # The product_id stored is actually the price_id for subscriptions
        return product_id

    @staticmethod
    def create_checkout_session(db: Session, user: User) -> dict:
        """Create a Stripe Checkout Session for Premium subscription."""
        if not settings.STRIPE_SECRET_KEY:
            raise AppError("STRIPE_NOT_CONFIGURED", 500, "Stripe not configured")

        if PlanService.get_plan(user).value != "FREE":
            raise AppError("ALREADY_PREMIUM", 400, "You are already on a paid plan")

        if not user.stripe_customer_id:
            raise AppError("STRIPE_CUSTOMER_MISSING", 500, "Stripe customer not found for user")

        try:
            session = stripe.checkout.Session.create(
                customer=user.stripe_customer_id,
                mode="subscription",
                line_items=[{"price": SubscriptionService._get_premium_price_id(), "quantity": 1}],
                success_url=f"{settings.STRIPE_SUCCESS_URL if hasattr(settings, 'STRIPE_SUCCESS_URL') else 'bagtrip://subscription/success'}",
                cancel_url=f"{settings.STRIPE_CANCEL_URL if hasattr(settings, 'STRIPE_CANCEL_URL') else 'bagtrip://subscription/cancel'}",
                metadata={"user_id": str(user.id)},
            )
            return {"url": session.url}
        except stripe.StripeError as e:
            logger.error(f"Stripe checkout error: {e}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, str(e)) from e

    @staticmethod
    def create_portal_session(db: Session, user: User) -> dict:
        """Create a Stripe Billing Portal session for managing subscription."""
        if not settings.STRIPE_SECRET_KEY:
            raise AppError("STRIPE_NOT_CONFIGURED", 500, "Stripe not configured")

        if not user.stripe_customer_id:
            raise AppError("STRIPE_CUSTOMER_MISSING", 500, "Stripe customer not found")

        try:
            session = stripe.billing_portal.Session.create(
                customer=user.stripe_customer_id,
                return_url="bagtrip://profile",
            )
            return {"url": session.url}
        except stripe.StripeError as e:
            logger.error(f"Stripe portal error: {e}", exc_info=True)
            raise AppError("STRIPE_ERROR", 500, str(e)) from e

    @staticmethod
    def get_status(db: Session, user: User) -> dict:
        """Return subscription status with plan info."""
        plan_info = PlanService.get_plan_info(db, user)
        return {
            **plan_info,
            "stripe_subscription_id": user.stripe_subscription_id,
            "plan_expires_at": user.plan_expires_at.isoformat() if user.plan_expires_at else None,
        }
