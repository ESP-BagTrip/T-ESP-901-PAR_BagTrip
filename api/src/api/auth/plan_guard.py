"""FastAPI dependencies for plan-based access control."""

from typing import Annotated

from fastapi import Depends
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.config.database import get_db
from src.models.user import User
from src.services.plan_service import PlanService
from src.utils.errors import AppError


async def require_ai_quota(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    """Dependency that checks the user has remaining AI generation quota.

    The quota check internally reconciles the local plan against Stripe,
    so a freshly-subscribed user whose ``customer.subscription.created``
    webhook hasn't landed yet is not blocked by the FREE quota.
    """
    await PlanService.check_ai_generation_quota(db, current_user)
    return current_user


async def require_premium(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    """Dependency that requires PREMIUM or ADMIN plan.

    Reconciles against Stripe so a paid user whose webhook is delayed is
    not bounced from premium-only routes.
    """
    plan = await PlanService.reconcile_plan_with_stripe(db, current_user)
    if plan.value == "FREE":
        raise AppError("UPGRADE_REQUIRED", 402, "Premium feature — upgrade your plan.")
    return current_user
