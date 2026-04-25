"""Subscription endpoints for Premium plan management."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.services.subscription_service import SubscriptionService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/subscription", tags=["Subscription"])


@router.post("/checkout", summary="Create Stripe Checkout session for Premium")
async def create_checkout(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.create_checkout_session(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/portal", summary="Create Stripe Billing Portal session")
async def create_portal(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
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
