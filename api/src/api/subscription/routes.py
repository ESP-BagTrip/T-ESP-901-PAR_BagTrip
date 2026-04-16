"""Subscription endpoints for Premium plan management."""

from typing import Annotated

from fastapi import APIRouter, Depends
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


@router.get("/status", summary="Get current subscription status")
async def get_status(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        return SubscriptionService.get_status(db, current_user)
    except AppError as e:
        raise create_http_exception(e) from e
