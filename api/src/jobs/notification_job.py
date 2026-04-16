"""Scheduled job: check and send planned notifications every 30 minutes."""

import asyncio
from datetime import UTC, date, datetime, timedelta

from sqlalchemy.orm import Session, selectinload

from src.config.database import SessionLocal
from src.enums import FlightOrderStatus, NotificationType, TripStatus
from src.models.activity import Activity
from src.models.flight_offer import FlightOffer
from src.models.flight_order import FlightOrder
from src.models.trip import Trip
from src.services.notification_service import NotificationService
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[NOTIFICATION_JOB]"
INTERVAL_SECONDS = 30 * 60  # 30 minutes
# Lock TTL — 2× interval so a slow tick can't get stepped on, not so long that
# a crashed worker leaves the lock stuck past the next tick.
_LOCK_TTL_SECONDS = 2 * INTERVAL_SECONDS


def _check_departure_reminders(db: Session) -> int:
    """Trip PLANNED, start_date = tomorrow → DEPARTURE_REMINDER."""
    tomorrow = date.today() + timedelta(days=1)
    # Eager-load baggage_items + shares so we don't issue one SELECT per trip in
    # the loop below. This job runs every 30 minutes over every PLANNED trip.
    trips = (
        db.query(Trip)
        .options(
            selectinload(Trip.baggage_items),
            selectinload(Trip.shares),
        )
        .filter(Trip.status == TripStatus.PLANNED, Trip.start_date == tomorrow)
        .all()
    )
    count = 0
    for trip in trips:
        baggage_items = trip.baggage_items
        total = len(baggage_items)
        packed = sum(1 for b in baggage_items if b.is_packed)

        if total > 0:
            baggage_status = f"Bagages : {packed}/{total} préparés."
        else:
            baggage_status = "Pensez à préparer vos bagages !"

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, NotificationType.DEPARTURE_REMINDER, timedelta(hours=20)
            ):
                continue
            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.DEPARTURE_REMINDER,
                title="Départ demain !",
                body=f"Votre voyage « {trip.title or 'sans titre'} » commence demain. {baggage_status}",
                data={"screen": "tripHome", "tripId": str(trip.id)},
            )
            count += 1
    return count


def _check_flight_alerts(db: Session, hours_before: float, notif_type: str, title: str) -> int:
    """Check for upcoming flights and send H-4 or H-1 alerts."""
    now = datetime.now(UTC)
    window_start = now + timedelta(hours=hours_before - 0.5)
    window_end = now + timedelta(hours=hours_before + 0.5)

    orders = db.query(FlightOrder).filter(FlightOrder.status == FlightOrderStatus.CONFIRMED).all()
    count = 0
    for order in orders:
        departure_time = _extract_departure_time(db, order)
        if not departure_time:
            continue
        if not (window_start <= departure_time <= window_end):
            continue

        trip = db.query(Trip).filter(Trip.id == order.trip_id).first()
        if not trip:
            continue

        # Extract flight info for enriched notifications
        flight_info = _extract_flight_info(db, order)

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db,
                uid,
                trip.id,
                notif_type,
                timedelta(hours=5),
                data_key="orderId",
                data_value=str(order.id),
            ):
                continue

            body = f"Votre vol pour « {trip.title or 'votre voyage'} » décolle bientôt !"
            data = {
                "screen": "tripHome",
                "tripId": str(trip.id),
                "orderId": str(order.id),
            }

            if notif_type == NotificationType.FLIGHT_H4 and flight_info.get("ticket_url"):
                data["ticketUrl"] = flight_info["ticket_url"]
                body += f" Billet : {flight_info['ticket_url']}"

            if notif_type == NotificationType.FLIGHT_H1:
                gate_info = flight_info.get("terminal_gate", "")
                if gate_info:
                    body += f" ({gate_info})"

            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=notif_type,
                title=title,
                body=body,
                data=data,
            )
            count += 1
    return count


def _extract_departure_time(db: Session, order: FlightOrder) -> datetime | None:
    """Parse departure time from FlightOffer.offer_json."""
    try:
        offer = db.query(FlightOffer).filter(FlightOffer.id == order.flight_offer_id).first()
        if not offer or not offer.offer_json:
            return None
        itineraries = offer.offer_json.get("itineraries", [])
        if not itineraries:
            return None
        segments = itineraries[0].get("segments", [])
        if not segments:
            return None
        dep_str = segments[0].get("departure", {}).get("at")
        if dep_str:
            return datetime.fromisoformat(dep_str).replace(tzinfo=UTC)
    except Exception:
        pass
    return None


def _extract_flight_info(db: Session, order: FlightOrder) -> dict:
    """Extract flight details (ticket_url, terminal, gate) from order + offer data."""
    info: dict = {}

    # ticket_url directly on FlightOrder
    if hasattr(order, "ticket_url") and order.ticket_url:
        info["ticket_url"] = order.ticket_url

    # Terminal and gate from offer_json
    try:
        offer = db.query(FlightOffer).filter(FlightOffer.id == order.flight_offer_id).first()
        if offer and offer.offer_json:
            itineraries = offer.offer_json.get("itineraries", [])
            if itineraries:
                segments = itineraries[0].get("segments", [])
                if segments:
                    departure = segments[0].get("departure", {})
                    terminal = departure.get("terminal")
                    if terminal:
                        info["terminal_gate"] = f"Terminal {terminal}"
    except Exception:
        pass

    return info


def _check_morning_summary(db: Session) -> int:
    """Trip ONGOING, activities today, between 07:00-07:30 UTC → MORNING_SUMMARY."""
    now = datetime.now(UTC)
    # Only run between 07:00 and 07:30 UTC
    if now.hour != 7 or now.minute > 30:
        return 0

    today = date.today()
    # Eager-load shares so the recipient lookup doesn't fire a follow-up query
    # per trip. Activities are still fetched with an explicit date filter — we
    # only want the subset dated "today", which is cheaper than loading all
    # activities and filtering in Python.
    trips = (
        db.query(Trip)
        .options(selectinload(Trip.shares))
        .filter(Trip.status == TripStatus.ONGOING)
        .all()
    )
    count = 0
    for trip in trips:
        activities = (
            db.query(Activity).filter(Activity.trip_id == trip.id, Activity.date == today).all()
        )
        if not activities:
            continue

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, NotificationType.MORNING_SUMMARY, timedelta(hours=20)
            ):
                continue

            activity_names = ", ".join(a.title for a in activities[:3])
            if len(activities) > 3:
                activity_names += f" (+{len(activities) - 3})"

            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.MORNING_SUMMARY,
                title=f"Programme du jour — {trip.title or 'Voyage'}",
                body=f"{len(activities)} activité(s) prévue(s) : {activity_names}",
                data={"screen": "activities", "tripId": str(trip.id)},
            )
            count += 1
    return count


def _check_activity_reminders(db: Session) -> int:
    """Activity today, start_time in 30min–1h30 → ACTIVITY_H1."""
    now = datetime.now(UTC)
    today = date.today()
    window_start = (now + timedelta(minutes=30)).time()
    window_end = (now + timedelta(minutes=90)).time()

    activities = (
        db.query(Activity)
        .filter(
            Activity.date == today,
            Activity.start_time.isnot(None),
            Activity.start_time >= window_start,
            Activity.start_time <= window_end,
        )
        .all()
    )
    count = 0
    for activity in activities:
        trip = db.query(Trip).filter(Trip.id == activity.trip_id).first()
        if not trip:
            continue

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db,
                uid,
                trip.id,
                NotificationType.ACTIVITY_H1,
                timedelta(hours=2),
                data_key="activityId",
                data_value=str(activity.id),
            ):
                continue
            location_hint = f" à {activity.location}" if activity.location else ""
            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.ACTIVITY_H1,
                title="Activité dans ~1h",
                body=f"« {activity.title} » commence bientôt !{location_hint}",
                data={
                    "screen": "activities",
                    "tripId": str(trip.id),
                    "activityId": str(activity.id),
                },
            )
            count += 1
    return count


def run_notification_checks() -> dict[str, int]:
    """Open a DB session and run all notification checks (sync)."""
    db = SessionLocal()
    try:
        results = {
            "departure_reminders": _check_departure_reminders(db),
            "flight_h4": _check_flight_alerts(db, 4, NotificationType.FLIGHT_H4, "Vol dans ~4h"),
            "flight_h1": _check_flight_alerts(db, 1, NotificationType.FLIGHT_H1, "Vol dans ~1h"),
            "morning_summary": _check_morning_summary(db),
            "activity_h1": _check_activity_reminders(db),
        }
        return results
    finally:
        db.close()


async def notification_scheduler() -> None:
    """Async loop: run notification checks every 30 minutes.

    The body is wrapped in a distributed Redis lock so that multi-worker
    FastAPI deployments don't duplicate push notifications. The
    `_already_sent()` window check remains as a belt-and-braces guard against
    cross-tick duplicates on the same instance.
    """
    logger.info(f"{TAG} Scheduler started (interval: {INTERVAL_SECONDS}s)")
    try:
        while True:
            async with redis_lock("job:notification", ttl_seconds=_LOCK_TTL_SECONDS) as acquired:
                if not acquired:
                    logger.info(f"{TAG} Lock held by peer worker, skipping tick")
                else:
                    try:
                        results = await asyncio.to_thread(run_notification_checks)
                        total = sum(results.values())
                        if total > 0:
                            logger.info(f"{TAG} Sent {total} notifications: {results}")
                        else:
                            logger.info(f"{TAG} No notifications to send")
                    except Exception as e:
                        logger.error(f"{TAG} Error: {e}")

            await asyncio.sleep(INTERVAL_SECONDS)
    except asyncio.CancelledError:
        logger.info(f"{TAG} Scheduler stopped")
        raise
