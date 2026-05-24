"""Daily job: purge stale refresh tokens.

Refresh tokens accumulate forever otherwise: every login/refresh mints a new
row, and rotation/revocation only flips `revoked` — nothing ever deletes them.
A token is purged when it is no longer useful for either authentication or
reuse-detection forensics:

  - it is revoked (rotated out or explicitly invalidated), OR
  - it expired more than 7 days ago.

The 7-day grace on expired-but-not-revoked rows keeps a short window where a
late refresh attempt with a just-expired token can still be distinguished from
an unknown token (theft signal) rather than silently 401-ing on a missing row.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta

from sqlalchemy import or_

from src.config.database import SessionLocal
from src.config.env import settings
from src.models.refresh_token import RefreshToken
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[REFRESH_TOKEN_CLEANUP_JOB]"
# Tokens expired longer than this are safe to drop (reuse-detection window).
_EXPIRY_GRACE_DAYS = 7
# Lock TTL — generous vs. the actual run time (a single bulk DELETE) so a slow
# Postgres can't make two workers double-run.
_LOCK_TTL_SECONDS = 5 * 60
_INTERVAL_SECONDS = 24 * 60 * 60  # daily


def purge_stale_refresh_tokens() -> int:
    """Delete revoked or long-expired refresh tokens. Returns the count purged."""
    db = SessionLocal()
    try:
        now = datetime.now(UTC)
        cutoff = now - timedelta(days=_EXPIRY_GRACE_DAYS)
        deleted = (
            db.query(RefreshToken)
            .filter(
                or_(
                    RefreshToken.revoked.is_(True),
                    RefreshToken.expires_at < cutoff,
                )
            )
            .delete(synchronize_session=False)
        )
        db.commit()
        return int(deleted)
    finally:
        db.close()


async def refresh_token_cleanup_scheduler() -> None:
    """Async loop: tick once per day, lock-protected for multi-worker safety."""
    if not settings.ENABLE_REFRESH_TOKEN_CLEANUP_JOB:
        logger.info(f"{TAG} Disabled via ENABLE_REFRESH_TOKEN_CLEANUP_JOB=False")
        return

    logger.info(f"{TAG} Scheduler started")
    try:
        while True:
            async with redis_lock(
                "job:refresh_token_cleanup", ttl_seconds=_LOCK_TTL_SECONDS
            ) as acquired:
                if not acquired:
                    logger.info(f"{TAG} Lock held by peer worker, skipping tick")
                else:
                    try:
                        n = await asyncio.to_thread(purge_stale_refresh_tokens)
                        if n:
                            logger.info(f"{TAG} {n} stale refresh tokens purged")
                    except Exception as exc:
                        logger.error(f"{TAG} Error: {exc}", exc_info=True)
            await asyncio.sleep(_INTERVAL_SECONDS)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
        raise
