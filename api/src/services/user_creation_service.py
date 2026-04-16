"""Single entry point for creating a User + attached account artifacts.

Register (`/auth/register`), Google Sign-In (`/auth/google`) and Apple Sign-In
(`/auth/apple`) all need the exact same bootstrap sequence once they have an
email and a password hash:

1. Insert the `User` row, flush so we have an id.
2. Create the Stripe customer and attach `stripe_customer_id` (fatal on failure —
   the account is meaningless without a billing profile).
3. Commit and refresh.
4. Claim any pending trip invites addressed to the email (best-effort).

This module owns that sequence so the three auth flows stop drifting from each
other. Callers remain responsible for producing the `password_hash` (real bcrypt
for register, dummy random hash for social providers) and for generating the
JWT tokens on top of the returned user.
"""

from __future__ import annotations

from sqlalchemy.orm import Session

from src.integrations.stripe.client import StripeClient
from src.models.user import User
from src.utils.errors import AppError
from src.utils.logger import logger


class UserCreationService:
    """Create a new user and wire up all the account-level side effects."""

    @staticmethod
    def create_and_setup_user(
        db: Session,
        *,
        email: str,
        password_hash: str,
        full_name: str | None = None,
        phone: str | None = None,
    ) -> User:
        """Persist a new `User`, create its Stripe customer and claim invites.

        Args:
            db: The SQLAlchemy session. The service commits on success and
                rolls back on Stripe failure — the caller must not start its
                own transaction around this call.
            email: The user's canonical email.
            password_hash: A bcrypt-hashed password (never the plain one).
                Social providers should pass a random dummy hash because they
                authenticate through the provider token, not this value.
            full_name: Optional display name forwarded to Stripe.
            phone: Optional phone number, stored on the user row.

        Returns:
            The newly created `User` with `stripe_customer_id` attached.

        Raises:
            AppError: On Stripe customer creation failure — the transaction is
                rolled back before the error is re-raised so the caller can map
                it to a 503.
        """
        user = User(
            email=email,
            password_hash=password_hash,
            full_name=full_name,
            phone=phone,
        )
        db.add(user)
        db.flush()  # need user.id for logging/stripe metadata

        try:
            stripe_customer = StripeClient.create_customer(email=email, name=full_name)
        except Exception as exc:
            logger.error(
                f"Failed to create Stripe customer for user {user.id}: {exc}",
                exc_info=True,
            )
            db.rollback()
            raise AppError(
                "STRIPE_CUSTOMER_CREATION_FAILED",
                503,
                "Failed to create payment profile. Please try again.",
            ) from exc

        user.stripe_customer_id = stripe_customer.id
        logger.info(f"Created Stripe customer {stripe_customer.id} for user {user.id}")

        db.commit()
        db.refresh(user)

        UserCreationService._claim_pending_invites(db, user)
        return user

    @staticmethod
    def _claim_pending_invites(db: Session, user: User) -> None:
        """Claim any pending share invites that match the user's email.

        Fire-and-forget: a failing claim must not prevent the caller from
        returning a successful auth response — the user still exists, the
        invite can be retried later through the UI.
        """
        # Local import: trip_share_service imports plan_service which imports
        # user-related modules, so we keep this late-bound to avoid cycles.
        from src.services.trip_share_service import TripShareService

        try:
            TripShareService.claim_pending_invites(db, email=user.email, user_id=user.id)
        except Exception as exc:
            logger.warn(
                "Failed to claim pending invites on signup",
                {"user_id": str(user.id), "error": str(exc)},
            )
