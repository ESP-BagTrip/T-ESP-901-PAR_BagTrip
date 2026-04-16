"""Daily job: auto-transition trip statuses based on dates."""

import asyncio
from datetime import UTC, datetime, timedelta

from src.config.database import SessionLocal
from src.services.trips_service import TripsService
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[TRIP_STATUS_JOB]"
# Lock TTL — large enough to cover a slow Postgres bulk UPDATE on thousands of
# rows, smaller than the 24h interval so a crashed worker releases it the next
# day at the latest.
_LOCK_TTL_SECONDS = 10 * 60  # 10 minutes


def _seconds_until_midnight_utc() -> float:
    """Return the number of seconds until the next midnight UTC."""
    now = datetime.now(UTC)
    tomorrow = (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
    return (tomorrow - now).total_seconds()


def run_trip_status_transitions() -> tuple[int, int]:
    """Open a DB session and run the bulk status updates (sync)."""
    db = SessionLocal()
    try:
        return TripsService.auto_transition_statuses(db)
    finally:
        db.close()


async def trip_status_scheduler() -> None:
    """Async loop: run once on startup then every midnight UTC.

    The body is wrapped in a distributed Redis lock so that multi-worker
    FastAPI deployments don't issue concurrent bulk `UPDATE trips SET status`.
    When Redis is unavailable the lock degrades to a best-effort no-op — see
    `distributed_lock.redis_lock` for the fallback semantics.
    """
    logger.info(f"{TAG} Scheduler started")
    try:
        while True:
            async with redis_lock("job:trip_status", ttl_seconds=_LOCK_TTL_SECONDS) as acquired:
                if not acquired:
                    logger.info(f"{TAG} Lock held by peer worker, skipping tick")
                else:
                    try:
                        p2o, o2c = await asyncio.to_thread(run_trip_status_transitions)
                        logger.info(
                            f"{TAG} Transitions applied — PLANNED→ONGOING: {p2o}, "
                            f"ONGOING→COMPLETED: {o2c}"
                        )
                    except Exception as e:
                        logger.error(f"{TAG} Error during transition: {e}")

            sleep_secs = _seconds_until_midnight_utc()
            logger.info(f"{TAG} Next run in {sleep_secs:.0f}s")
            await asyncio.sleep(sleep_secs)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
