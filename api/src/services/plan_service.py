"""Service for plan quota enforcement and feature gating.

Plan resolution
---------------
Two sources hold a user's plan:

- Stripe — the authoritative source. State changes (subscribe / cancel
  / dunning) propagate via the ``customer.subscription.*`` webhooks.
- ``users.plan`` — the local mirror those webhooks update.

In production with a healthy webhook the two stay in sync. In dev (no
``stripe listen`` tunnel forwarding events) and during the few hundred
milliseconds between confirm and webhook delivery, they diverge: a paid
user sees ``plan='FREE'`` and gets ``402 AI_QUOTA_EXCEEDED`` on the
next AI generation even though their card was charged.

``reconcile_plan_with_stripe`` removes that class of bug. Every
plan-aware path (``check_ai_generation_quota``, ``get_plan_info``,
``require_premium``, ``get_subscription_details``) calls it instead of
reading ``user.plan`` directly. The method:

1. Returns the local plan immediately when there is no
   ``stripe_subscription_id`` (no need to call Stripe for a free user).
2. Returns the local plan when it is already PREMIUM or ADMIN — only
   FREE-with-subscription is suspect.
3. On suspicion, queries Stripe (with a 60 s Redis cache so a burst of
   quota checks doesn't hammer the API) and persists the corrected
   ``user.plan`` + ``plan_expires_at`` if Stripe says active.
4. Persists the corrected FREE state and clears the dangling
   subscription id when Stripe says canceled / expired / unpaid.
5. Logs every persisted change to the audit trail so we can measure
   the webhook gap and notice if it grows.

The method degrades gracefully: any Stripe error or unparsable
response just returns the local plan unchanged so an Amadeus-level
outage upstream doesn't bring quota enforcement down.
"""

from __future__ import annotations

import asyncio
import json
from datetime import UTC, datetime

import stripe
from sqlalchemy.orm import Session

from src.config.env import settings
from src.config.plans import PLAN_LIMITS, UserPlan
from src.integrations.redis_client import get_redis_client
from src.integrations.stripe.client import StripeClient
from src.models.user import User
from src.services.audit_service import AuditService
from src.utils.errors import AppError
from src.utils.logger import logger

# Statuses that grant Premium per Stripe's grace policy.
_STRIPE_ACTIVE_STATUSES = frozenset({"active", "trialing", "past_due"})
# Statuses that mean "no Premium" — webhook would normally have flipped
# the user back, but we do it ourselves on read when we see them.
_STRIPE_DEAD_STATUSES = frozenset({"canceled", "unpaid", "incomplete_expired"})

# Cache lifetime for ``stripe.Subscription.retrieve`` results during the
# self-heal flow. 60 s strikes the trade-off:
# - long enough to amortize a burst of quota checks during one user
#   session (typical ~10-20 plan look-ups);
# - short enough that a real-world cancellation propagates within a
#   minute even when the webhook is silent.
_STRIPE_PLAN_CACHE_TTL_SECONDS = 60


class PlanService:
    """Stateless helpers for plan-based access control."""

    # ------------------------------------------------------------------
    # Local-only resolution
    # ------------------------------------------------------------------

    @staticmethod
    def get_plan(user: User) -> UserPlan:
        """Read ``user.plan`` and coerce to the enum (FREE on bad value)."""
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
    def can_access_feature(user: User, feature: str) -> bool:
        """Generic feature gate. Returns True if the user's plan allows the feature."""
        limits = PlanService.get_limits(user)
        value = limits.get(feature)
        if isinstance(value, bool):
            return value
        return True

    # ------------------------------------------------------------------
    # Stripe-aware resolution
    # ------------------------------------------------------------------

    @staticmethod
    async def reconcile_plan_with_stripe(db: Session, user: User) -> UserPlan:
        """Return the user's effective plan, healing local-vs-Stripe drift.

        Cheap on the hot path: only users that look FREE locally **and**
        have a ``stripe_subscription_id`` actually trigger a Stripe call
        (or a Redis cache hit). Everyone else short-circuits.

        Persists the corrected plan + expiry to the DB so subsequent
        reads stay fast and so the rest of the app sees a consistent
        view of the user.
        """
        local_plan = PlanService.get_plan(user)

        # Hot path 1: ADMIN / PREMIUM — the only way to drop is via the
        # ``customer.subscription.deleted`` webhook, which we trust here
        # because false negatives expire on next month-end roll anyway.
        if local_plan != UserPlan.FREE:
            return local_plan

        # Hot path 2: FREE without a subscription id means there's
        # nothing to reconcile.
        if not user.stripe_subscription_id or not settings.STRIPE_SECRET_KEY:
            return local_plan

        snapshot = await _fetch_subscription_snapshot(user.stripe_subscription_id)
        if snapshot is None:
            # Stripe unreachable / parse error — defer to local plan and
            # let the next call retry.
            return local_plan

        return _apply_snapshot_to_user(db, user, snapshot)

    # ------------------------------------------------------------------
    # Quota / counters (call ``reconcile`` first if you need fresh plan)
    # ------------------------------------------------------------------

    @staticmethod
    async def check_ai_generation_quota(db: Session, user: User) -> None:
        """Raise AppError if the user has exhausted their monthly AI quota.

        Reconciles the plan against Stripe before reading the limit, so a
        paid user whose webhook hasn't landed yet is not blocked.
        """
        plan = await PlanService.reconcile_plan_with_stripe(db, user)
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
    async def get_plan_info(db: Session, user: User) -> dict:
        """Return plan + limits + current usage for API responses.

        Reconciles the plan against Stripe so the UI never shows a
        stale FREE badge to a freshly-subscribed user.
        """
        plan = await PlanService.reconcile_plan_with_stripe(db, user)
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


# =====================================================================
# Internal helpers — kept module-level so they can be unit-tested in
# isolation and so the class above stays readable.
# =====================================================================


def _cache_key(subscription_id: str) -> str:
    return f"plan_sync:sub:{subscription_id}"


async def _fetch_subscription_snapshot(subscription_id: str) -> dict | None:
    """Return ``{"status", "current_period_end"}`` for the subscription.

    Tries Redis first (TTL 60 s), then Stripe. ``None`` on any error
    so callers can fall back to the local plan rather than raising.
    """
    cached = _read_cache(subscription_id)
    if cached is not None:
        return cached

    try:
        # The Stripe Python SDK is sync; running it in a worker thread
        # keeps the event loop free for other requests.
        sub = await asyncio.to_thread(StripeClient.retrieve_subscription, subscription_id)
    except stripe.StripeError as exc:
        logger.warn(
            "PlanService.reconcile: Stripe retrieve_subscription failed",
            {"subscription_id": subscription_id, "error": str(exc)},
        )
        return None
    except Exception as exc:  # pragma: no cover - defensive
        logger.warn(
            "PlanService.reconcile: unexpected Stripe SDK error",
            {"subscription_id": subscription_id, "error": str(exc)},
        )
        return None

    snapshot = {
        "status": getattr(sub, "status", None),
        "current_period_end": getattr(sub, "current_period_end", None),
    }
    _write_cache(subscription_id, snapshot)
    return snapshot


def _read_cache(subscription_id: str) -> dict | None:
    client = get_redis_client()
    if client is None:
        return None
    try:
        raw = client.get(_cache_key(subscription_id))
    except Exception as exc:  # pragma: no cover
        logger.warn("PlanService.reconcile: cache read failed", {"error": str(exc)})
        return None
    if not raw:
        return None
    try:
        return json.loads(raw if isinstance(raw, str) else raw.decode("utf-8"))
    except (ValueError, AttributeError):
        return None


def _write_cache(subscription_id: str, snapshot: dict) -> None:
    client = get_redis_client()
    if client is None:
        return
    try:
        client.set(
            _cache_key(subscription_id),
            json.dumps(snapshot),
            ex=_STRIPE_PLAN_CACHE_TTL_SECONDS,
        )
    except Exception as exc:  # pragma: no cover
        logger.warn("PlanService.reconcile: cache write failed", {"error": str(exc)})


def _apply_snapshot_to_user(db: Session, user: User, snapshot: dict) -> UserPlan:
    """Persist the Stripe-truth plan onto ``user`` and audit the change."""
    status_val = snapshot.get("status")
    period_end = snapshot.get("current_period_end")

    if status_val in _STRIPE_ACTIVE_STATUSES:
        return _heal_to_premium(db, user, period_end)
    if status_val in _STRIPE_DEAD_STATUSES:
        return _heal_to_free(db, user, status_val)

    # Statuses we don't act on (e.g. ``incomplete``, ``paused``):
    # treat as not-yet-Premium and let the local FREE stand.
    return UserPlan.FREE


def _heal_to_premium(db: Session, user: User, period_end: int | None) -> UserPlan:
    user.plan = UserPlan.PREMIUM.value
    if period_end:
        user.plan_expires_at = datetime.fromtimestamp(period_end, tz=UTC)
    db.commit()
    db.refresh(user)
    AuditService.log(
        db,
        actor_id=user.id,
        action="PLAN_RECONCILED_TO_PREMIUM",
        entity_type="user",
        entity_id=user.id,
        metadata={
            "subscription_id": user.stripe_subscription_id,
            "stripe_period_end": period_end,
        },
    )
    logger.info(
        "PlanService.reconcile: healed FREE → PREMIUM",
        {"user_id": str(user.id), "subscription_id": user.stripe_subscription_id},
    )
    return UserPlan.PREMIUM


def _heal_to_free(db: Session, user: User, stripe_status: str | None) -> UserPlan:
    # Already FREE locally — only the dangling subscription_id needs clearing.
    cleared_id = user.stripe_subscription_id
    user.stripe_subscription_id = None
    user.plan_expires_at = None
    db.commit()
    db.refresh(user)
    AuditService.log(
        db,
        actor_id=user.id,
        action="PLAN_RECONCILED_TO_FREE",
        entity_type="user",
        entity_id=user.id,
        metadata={
            "cleared_subscription_id": cleared_id,
            "stripe_status": stripe_status,
        },
    )
    logger.info(
        "PlanService.reconcile: cleared dead Stripe subscription",
        {"user_id": str(user.id), "stripe_status": stripe_status},
    )
    return UserPlan.FREE
