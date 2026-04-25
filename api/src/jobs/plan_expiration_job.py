"""Hourly job: downgrade users whose Premium plan has expired.

A user is downgraded to FREE when:
  - their `plan` is `PREMIUM` (admins are never touched), and
  - `plan_expires_at` is in the past, and
  - they have no active `stripe_subscription_id` (an active subscription means
    the next renewal webhook will refresh `plan_expires_at`).

Without this job, a user whose subscription was canceled outside Stripe
(manual deletion, dispute, dunning failure not surfaced via webhook) keeps
Premium access forever. The job is the safety net.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime

from src.config.database import SessionLocal
from src.config.env import settings
from src.models.user import User
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[PLAN_EXPIRATION_JOB]"
# Lock TTL — generous compared to the actual run time (a single bulk SELECT +
# UPDATE on users) so a slow Postgres can't make two workers double-update.
_LOCK_TTL_SECONDS = 5 * 60
_INTERVAL_SECONDS = 60 * 60  # hourly


def downgrade_expired_plans() -> int:
    """Downgrade expired PREMIUM users to FREE. Returns the count downgraded."""
    db = SessionLocal()
    try:
        now = datetime.now(UTC)
        users = (
            db.query(User)
            .filter(
                User.plan == "PREMIUM",
                User.plan_expires_at.isnot(None),
                User.plan_expires_at < now,
                User.stripe_subscription_id.is_(None),
            )
            .all()
        )
        for user in users:
            logger.info(
                f"{TAG} Downgrading user {user.id} (expired_at={user.plan_expires_at.isoformat()})"
            )
            user.plan = "FREE"
            user.plan_expires_at = None
        db.commit()
        return len(users)
    finally:
        db.close()


async def plan_expiration_scheduler() -> None:
    """Async loop: tick once per hour, lock-protected for multi-worker safety."""
    if not settings.ENABLE_PLAN_EXPIRATION_JOB:
        logger.info(f"{TAG} Disabled via ENABLE_PLAN_EXPIRATION_JOB=False")
        return

    logger.info(f"{TAG} Scheduler started")
    try:
        while True:
            async with redis_lock("job:plan_expiration", ttl_seconds=_LOCK_TTL_SECONDS) as acquired:
                if not acquired:
                    logger.info(f"{TAG} Lock held by peer worker, skipping tick")
                else:
                    try:
                        n = await asyncio.to_thread(downgrade_expired_plans)
                        if n:
                            logger.info(f"{TAG} {n} users downgraded to FREE")
                    except Exception as exc:
                        logger.error(f"{TAG} Error: {exc}", exc_info=True)
            await asyncio.sleep(_INTERVAL_SECONDS)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
        raise
