"""Plan constants and limits for FREE / PREMIUM / ADMIN tiers."""

from enum import StrEnum


class UserPlan(StrEnum):
    FREE = "FREE"
    PREMIUM = "PREMIUM"
    ADMIN = "ADMIN"


PLAN_LIMITS = {
    UserPlan.FREE: {
        "ai_generations_per_month": 3,
        "viewers_per_trip": 2,
        "offline_notifications": False,
        "post_voyage_ai": False,
    },
    UserPlan.PREMIUM: {
        "ai_generations_per_month": None,  # unlimited
        "viewers_per_trip": 10,
        "offline_notifications": True,
        "post_voyage_ai": True,
    },
    UserPlan.ADMIN: {
        "ai_generations_per_month": None,
        "viewers_per_trip": None,  # unlimited
        "offline_notifications": True,
        "post_voyage_ai": True,
    },
}
