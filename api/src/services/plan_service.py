"""Service for plan quota enforcement and feature gating."""

from datetime import UTC, datetime

from sqlalchemy.orm import Session

from src.config.plans import PLAN_LIMITS, UserPlan
from src.models.user import User
from src.utils.errors import AppError


class PlanService:
    """Stateless helpers for plan-based access control."""

    @staticmethod
    def get_plan(user: User) -> UserPlan:
        try:
            return UserPlan(user.plan)
        except (ValueError, AttributeError):
            return UserPlan.FREE

    @staticmethod
    def get_limits(user: User) -> dict:
        return PLAN_LIMITS.get(PlanService.get_plan(user), PLAN_LIMITS[UserPlan.FREE])

    @staticmethod
    def get_share_limit(user: User) -> int | None:
        """Return the max viewers per trip (None = unlimited)."""
        return PlanService.get_limits(user).get("viewers_per_trip")

    @staticmethod
    def check_ai_generation_quota(db: Session, user: User) -> None:
        """Raise AppError if the user has exhausted their monthly AI quota."""
        plan = PlanService.get_plan(user)
        limit = PLAN_LIMITS[plan]["ai_generations_per_month"]
        if limit is None:
            return  # unlimited

        now = datetime.now(UTC)

        # Auto-reset if we crossed into a new month
        if user.ai_generations_reset_at is not None:
            reset = user.ai_generations_reset_at
            if (reset.year, reset.month) != (now.year, now.month):
                user.ai_generations_count = 0
                user.ai_generations_reset_at = now
                db.commit()
                db.refresh(user)

        if user.ai_generations_count >= limit:
            raise AppError(
                "AI_QUOTA_EXCEEDED",
                402,
                f"Monthly AI generation limit ({limit}) reached. Upgrade to Premium for unlimited.",
            )

    @staticmethod
    def increment_ai_generation(db: Session, user: User) -> None:
        """Increment the user's AI generation counter."""
        now = datetime.now(UTC)
        if user.ai_generations_reset_at is None:
            user.ai_generations_reset_at = now
        user.ai_generations_count = (user.ai_generations_count or 0) + 1
        db.commit()

    @staticmethod
    def can_access_feature(user: User, feature: str) -> bool:
        """Generic feature gate. Returns True if the user's plan allows the feature."""
        limits = PlanService.get_limits(user)
        value = limits.get(feature)
        if isinstance(value, bool):
            return value
        return True

    @staticmethod
    def get_plan_info(db: Session, user: User) -> dict:
        """Return plan + limits + current usage for API responses."""
        plan = PlanService.get_plan(user)
        limits = PLAN_LIMITS[plan]
        monthly_limit = limits["ai_generations_per_month"]

        now = datetime.now(UTC)
        count = user.ai_generations_count or 0

        # Check if count should have been reset
        if user.ai_generations_reset_at is not None:
            reset = user.ai_generations_reset_at
            if (reset.year, reset.month) != (now.year, now.month):
                count = 0

        remaining: int | None = None
        if monthly_limit is not None:
            remaining = max(0, monthly_limit - count)

        return {
            "plan": plan.value,
            "ai_generations_remaining": remaining,
            "viewers_per_trip": limits["viewers_per_trip"],
            "offline_notifications": limits["offline_notifications"],
            "post_voyage_ai": limits["post_voyage_ai"],
        }
