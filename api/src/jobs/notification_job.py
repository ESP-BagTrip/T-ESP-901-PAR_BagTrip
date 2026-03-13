"""Scheduled job: check and send planned notifications every 30 minutes."""

import asyncio
from datetime import UTC, date, datetime, timedelta

from sqlalchemy.orm import Session

from src.config.database import SessionLocal
from src.models.activity import Activity
from src.models.flight_offer import FlightOffer
from src.models.flight_order import FlightOrder
from src.models.trip import Trip
from src.services.notification_service import NotificationService
from src.utils.logger import logger

TAG = "[NOTIFICATION_JOB]"
INTERVAL_SECONDS = 30 * 60  # 30 minutes


def _check_departure_reminders(db: Session) -> int:
    """Trip PLANNED, start_date = tomorrow → DEPARTURE_REMINDER."""
    tomorrow = date.today() + timedelta(days=1)
    trips = (
        db.query(Trip)
        .filter(Trip.status == "PLANNED", Trip.start_date == tomorrow)
        .all()
    )
    count = 0
    for trip in trips:
        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, "DEPARTURE_REMINDER", timedelta(hours=20)
            ):
                continue
            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type="DEPARTURE_REMINDER",
                title="Départ demain !",
                body=f"Votre voyage « {trip.title or 'sans titre'} » commence demain. Bon voyage !",
                data={"screen": "tripHome", "tripId": str(trip.id)},
            )
            count += 1
    return count


def _check_flight_alerts(db: Session, hours_before: float, notif_type: str, title: str) -> int:
    """Check for upcoming flights and send H-4 or H-1 alerts."""
    now = datetime.now(UTC)
    window_start = now + timedelta(hours=hours_before - 0.5)
    window_end = now + timedelta(hours=hours_before + 0.5)

    orders = (
        db.query(FlightOrder)
        .filter(FlightOrder.status == "CONFIRMED")
        .all()
    )
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

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            dedup_key = f"{notif_type}_{order.id}"
            if NotificationService._already_sent(db, uid, trip.id, dedup_key, timedelta(hours=5)):
                continue
            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=notif_type,
                title=title,
                body=f"Votre vol pour « {trip.title or 'votre voyage'} » décolle bientôt !",
                data={"screen": "tripHome", "tripId": str(trip.id)},
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


def _check_morning_summary(db: Session) -> int:
    """Trip ONGOING, activities today, between 07:00-07:30 UTC → MORNING_SUMMARY."""
    now = datetime.now(UTC)
    # Only run between 07:00 and 07:30 UTC
    if now.hour != 7 or now.minute > 30:
        return 0

    today = date.today()
    trips = db.query(Trip).filter(Trip.status == "ONGOING").all()
    count = 0
    for trip in trips:
        activities = (
            db.query(Activity)
            .filter(Activity.trip_id == trip.id, Activity.date == today)
            .all()
        )
        if not activities:
            continue

        recipients = NotificationService._get_trip_recipients(db, trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, "MORNING_SUMMARY", timedelta(hours=20)
            ):
                continue

            activity_names = ", ".join(a.title for a in activities[:3])
            if len(activities) > 3:
                activity_names += f" (+{len(activities) - 3})"

            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type="MORNING_SUMMARY",
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
            dedup_key = f"ACTIVITY_H1_{activity.id}"
            if NotificationService._already_sent(db, uid, trip.id, dedup_key, timedelta(hours=2)):
                continue
            NotificationService.create_and_send(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type="ACTIVITY_H1",
                title="Activité dans ~1h",
                body=f"« {activity.title} » commence bientôt !",
                data={"screen": "activities", "tripId": str(trip.id)},
            )
            count += 1
    return count


def run_notification_checks() -> dict[str, int]:
    """Open a DB session and run all notification checks (sync)."""
    db = SessionLocal()
    try:
        results = {
            "departure_reminders": _check_departure_reminders(db),
            "flight_h4": _check_flight_alerts(db, 4, "FLIGHT_H4", "Vol dans ~4h"),
            "flight_h1": _check_flight_alerts(db, 1, "FLIGHT_H1", "Vol dans ~1h"),
            "morning_summary": _check_morning_summary(db),
            "activity_h1": _check_activity_reminders(db),
        }
        return results
    finally:
        db.close()


async def notification_scheduler() -> None:
    """Async loop: run notification checks every 30 minutes."""
    logger.info(f"{TAG} Scheduler started (interval: {INTERVAL_SECONDS}s)")
    try:
        while True:
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
