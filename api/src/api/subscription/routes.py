"""Subscription endpoints for Premium plan management."""

from typing import Annotated

from fastapi import APIRouter, Body, Depends, Query
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.services.subscription_service import SubscriptionService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/subscription", tags=["Subscription"])


@router.post(
    "/checkout",
    summary="[Legacy] Create Stripe Checkout session for Premium (web fallback)",
    description=(
        "Returns a Stripe Checkout URL. Mobile clients should use "
        "POST /subscription/start instead — that flow drives the native "
        "PaymentSheet and never leaves the app."
    ),
)
async def create_checkout(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.create_checkout_session(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/start",
    summary="Start Premium subscription for native PaymentSheet (mobile)",
    description=(
        "Creates a subscription in `default_incomplete` mode and returns "
        "everything the Stripe mobile SDK needs: PaymentIntent client "
        "secret, ephemeral key, customer id, subscription id. The user "
        "completes payment in the native PaymentSheet — no browser, no "
        "Checkout URL."
    ),
)
async def start_subscription(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.start_subscription(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/payment-method/setup",
    summary="Start in-app payment method update (SetupIntent)",
    description=(
        "Returns a SetupIntent client secret + ephemeral key for the "
        "Stripe mobile SDK. Lets the user attach / change their card "
        "in the native PaymentSheet without ever leaving the app — "
        "the legacy path was to bounce them out to the Stripe Billing "
        "Portal."
    ),
)
async def start_payment_method_update(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.start_payment_method_update(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/payment-method/attach",
    summary="Attach a payment method as the subscription default",
)
async def attach_payment_method(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    payment_method_id: Annotated[str, Body(..., embed=True, alias="paymentMethodId")],
):
    """Wire a freshly-confirmed PaymentMethod as the subscription default.

    Called by the mobile app right after the SetupIntent confirms in the
    native PaymentSheet — the SDK returns the PaymentMethod id, the app
    POSTs it here so the next renewal charges the new card.
    """
    try:
        return SubscriptionService.attach_default_payment_method(
            db, current_user, payment_method_id
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/portal", summary="Create Stripe Billing Portal session (fallback)")
async def create_portal(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Hosted portal — kept for the rare cases the native flows don't cover.

    Mobile clients should open this URL in an in-app browser
    (`SFSafariViewController` on iOS, Custom Tabs on Android) rather than
    bouncing the user out to the system browser.
    """
    try:
        return SubscriptionService.create_portal_session(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/status", summary="Get current subscription status (lightweight)")
async def get_status(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.get_status(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/me",
    summary="Subscription details (renewal date, payment method, cancel state)",
)
async def get_subscription_me(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Detailed view used by the "Manage my subscription" screen."""
    try:
        return SubscriptionService.get_subscription_details(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/cancel", summary="Cancel subscription at period end")
async def cancel_subscription(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Schedules cancellation — user keeps Premium until current_period_end."""
    try:
        return SubscriptionService.cancel_subscription(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/reactivate", summary="Reactivate a subscription scheduled for cancellation")
async def reactivate_subscription(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Undoes cancel_at_period_end while still in the current billing period."""
    try:
        return SubscriptionService.reactivate_subscription(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/invoices", summary="List recent invoices for the current user")
async def list_invoices(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    limit: Annotated[int, Query(ge=1, le=50, description="Max invoices to return")] = 12,
):
    try:
        return {"invoices": SubscriptionService.list_invoices(db, current_user, limit=limit)}
    except AppError as e:
        raise create_http_exception(e) from e
