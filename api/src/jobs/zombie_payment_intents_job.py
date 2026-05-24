"""Daily job: cancel BookingIntents stuck in AUTHORIZED for too long.

Stripe auto-cancels uncaptured PaymentIntents after 7 days. We pre-empt that at
6 days so:
  - The local DB status reflects reality before Stripe forces our hand.
  - We control the message back to the user (notification, log) rather than
    discovering it via a `payment_intent.canceled` webhook with no context.

This complements the `payment_intent.canceled` webhook handler, which still
fires if Stripe cancels first — we just want to be proactive.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta

import stripe

from src.config.database import SessionLocal
from src.config.env import settings
from src.enums import BookingIntentStatus
from src.integrations.stripe.client import StripeClient
from src.models.booking_intent import BookingIntent
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[ZOMBIE_PI_JOB]"
_LOCK_TTL_SECONDS = 10 * 60
_INTERVAL_SECONDS = 24 * 60 * 60
# Stripe cancels at 7 days; leave a 24h safety margin so we cancel first.
_AUTHORIZED_MAX_AGE_DAYS = 6


def _idem_key(intent_id: str) -> str:
    return f"zombie-cleanup-{intent_id}-v1"


def cancel_zombie_intents() -> int:
    """Cancel BookingIntents stuck in AUTHORIZED past the safety window."""
    db = SessionLocal()
    try:
        threshold = datetime.now(UTC) - timedelta(days=_AUTHORIZED_MAX_AGE_DAYS)
        stale = (
            db.query(BookingIntent)
            .filter(
                BookingIntent.status == BookingIntentStatus.AUTHORIZED,
                BookingIntent.created_at < threshold,
                BookingIntent.stripe_payment_intent_id.isnot(None),
            )
            .all()
        )

        cancelled = 0
        for intent in stale:
            try:
                StripeClient.cancel_payment_intent(
                    intent.stripe_payment_intent_id,
                    idempotency_key=_idem_key(str(intent.id)),
                )
            except stripe.StripeError as exc:
                # The PI may already be canceled / captured by another path —
                # log but proceed with the local status update so the row
                # doesn't stay zombified forever.
                logger.warn(
                    f"{TAG} Failed to cancel Stripe PI "
                    f"{intent.stripe_payment_intent_id} for intent {intent.id}: {exc}"
                )
            intent.status = BookingIntentStatus.CANCELLED
            intent.last_error = {
                "reason": "zombie_cleanup",
                "cancelled_after_days": _AUTHORIZED_MAX_AGE_DAYS,
            }
            cancelled += 1
        db.commit()
        return cancelled
    finally:
        db.close()


async def zombie_payment_intents_scheduler() -> None:
    """Async loop: tick once a day, lock-protected for multi-worker safety."""
    if not settings.ENABLE_ZOMBIE_PI_JOB:
        logger.info(f"{TAG} Disabled via ENABLE_ZOMBIE_PI_JOB=False")
        return

    logger.info(f"{TAG} Scheduler started")
    try:
        while True:
            async with redis_lock(
                "job:zombie_payment_intents", ttl_seconds=_LOCK_TTL_SECONDS
            ) as acquired:
                if not acquired:
                    logger.info(f"{TAG} Lock held by peer worker, skipping tick")
                else:
                    try:
                        n = await asyncio.to_thread(cancel_zombie_intents)
                        if n:
                            logger.info(f"{TAG} {n} zombie intents cancelled")
                    except Exception as exc:
                        logger.error(f"{TAG} Error: {exc}", exc_info=True)
            await asyncio.sleep(_INTERVAL_SECONDS)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
        raise
