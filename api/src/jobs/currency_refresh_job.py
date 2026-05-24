"""Periodic ECB currency rate refresh (topic 04b phase 3)."""

from __future__ import annotations

import asyncio

from src.services.currency_service import refresh_rates_async
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[CURRENCY_REFRESH_JOB]"

# Aligned with the in-process cache TTL (12h) so the cache never reaches
# the cold-fallback path under nominal conditions.
_REFRESH_INTERVAL_SECONDS = 12 * 3600

# Lock TTL big enough to cover a slow ECB fetch + parse, smaller than the
# refresh interval so a crashed worker releases it before the next tick.
_LOCK_TTL_SECONDS = 5 * 60


async def currency_refresh_scheduler() -> None:
    """Async loop : warm the rate cache, then re-run every 12h.

    Wrapped in a Redis lock so that a multi-worker deployment doesn't
    fan-out N concurrent ECB fetches. Lock degrades to best-effort
    no-op when Redis is unavailable (see ``distributed_lock.redis_lock``).
    Failures inside :func:`refresh_rates_async` are already swallowed
    by the service — this scheduler only reacts to scheduling-level
    issues (cancellation, lock contention).
    """
    # Boot tick: warm the cache immediately so the very first incoming
    # request already sees real rates.
    await _refresh_with_lock()

    while True:
        try:
            await asyncio.sleep(_REFRESH_INTERVAL_SECONDS)
            await _refresh_with_lock()
        except asyncio.CancelledError:
            logger.info(f"{TAG} scheduler cancelled, exiting")
            raise
        except Exception as exc:  # noqa: BLE001 — scheduler must survive exceptions
            logger.warn(f"{TAG} unexpected error, continuing", {"error": str(exc)})


async def _refresh_with_lock() -> None:
    async with redis_lock("currency_refresh_job", ttl_seconds=_LOCK_TTL_SECONDS) as acquired:
        if not acquired:
            logger.info(f"{TAG} another worker holds the lock, skipping")
            return
        written = await refresh_rates_async()
        logger.info(f"{TAG} refresh tick complete", {"pairs_written": written})
