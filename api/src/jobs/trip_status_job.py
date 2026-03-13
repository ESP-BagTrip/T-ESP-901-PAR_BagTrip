"""Daily job: auto-transition trip statuses based on dates."""

import asyncio
from datetime import UTC, datetime, timedelta

from src.config.database import SessionLocal
from src.services.trips_service import TripsService
from src.utils.logger import logger

TAG = "[TRIP_STATUS_JOB]"


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
    """Async loop: run once on startup then every midnight UTC."""
    logger.info(f"{TAG} Scheduler started")
    try:
        while True:
            try:
                p2o, o2c = await asyncio.to_thread(run_trip_status_transitions)
                logger.info(
                    f"{TAG} Transitions applied — "
                    f"PLANNED→ONGOING: {p2o}, ONGOING→COMPLETED: {o2c}"
                )
            except Exception as e:
                logger.error(f"{TAG} Error during transition: {e}")

            sleep_secs = _seconds_until_midnight_utc()
            logger.info(f"{TAG} Next run in {sleep_secs:.0f}s")
            await asyncio.sleep(sleep_secs)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
