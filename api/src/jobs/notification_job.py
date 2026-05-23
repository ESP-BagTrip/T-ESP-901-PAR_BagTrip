"""Scheduled job: check and send planned notifications every 30 minutes.

All notification copy is localized per recipient via
``NotificationService.send_localized`` — the job never builds display strings
itself. The locale is resolved from each recipient's most recent device token.
"""

import asyncio
from datetime import UTC, date, datetime, timedelta, tzinfo
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy.orm import Session, joinedload, selectinload

from src.config.database import SessionLocal
from src.enums import FlightOrderStatus, NotificationType, TripStatus
from src.integrations.aviation_data import aviation_data_service
from src.models.activity import Activity
from src.models.flight_offer import FlightOffer
from src.models.flight_order import FlightOrder
from src.models.trip import Trip
from src.services.device_token_service import DeviceTokenService
from src.services.notification_messages import (
    activity_location_suffix,
    baggage_status,
    flight_gate_suffix,
    flight_ticket_suffix,
    untitled_trip,
)
from src.services.notification_service import NotificationService
from src.utils.distributed_lock import redis_lock
from src.utils.logger import logger

TAG = "[NOTIFICATION_JOB]"
INTERVAL_SECONDS = 30 * 60  # 30 minutes
# Lock TTL — 2× interval so a slow tick can't get stepped on, not so long that
# a crashed worker leaves the lock stuck past the next tick.
_LOCK_TTL_SECONDS = 2 * INTERVAL_SECONDS


def _safe_zone(name: str | None) -> tzinfo:
    """Resolve an IANA timezone name, falling back to UTC on anything weird."""
    if not name:
        return UTC
    try:
        return ZoneInfo(name)
    except (ZoneInfoNotFoundError, ValueError, OSError):
        return UTC


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

        recipients = NotificationService._get_trip_recipients(trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, NotificationType.DEPARTURE_REMINDER, timedelta(hours=20)
            ):
                continue
            locale = DeviceTokenService.get_locale_for_user(db, uid)
            NotificationService.send_localized(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.DEPARTURE_REMINDER,
                context={
                    "trip_title": trip.title or untitled_trip(locale),
                    "baggage_status": baggage_status(locale, packed, total),
                },
                data={"screen": "tripHome", "tripId": str(trip.id)},
                locale=locale,
            )
            count += 1
    return count


def _check_flight_alerts(db: Session, hours_before: float, notif_type: str) -> int:
    """Check for upcoming flights and send H-4 or H-1 alerts."""
    now = datetime.now(UTC)
    window_start = now + timedelta(hours=hours_before - 0.5)
    window_end = now + timedelta(hours=hours_before + 0.5)

    # Bound the scan to flights of still-active trips, and eager-load the offer
    # so departure-time + terminal parsing don't issue a query per row.
    orders = (
        db.query(FlightOrder)
        .join(Trip, Trip.id == FlightOrder.trip_id)
        .options(joinedload(FlightOrder.flight_offer))
        .filter(
            FlightOrder.status == FlightOrderStatus.CONFIRMED,
            Trip.status.in_([TripStatus.PLANNED, TripStatus.ONGOING]),
        )
        .all()
    )
    if not orders:
        return 0

    # Batch-load the trips (with shares) referenced by the matching orders.
    trip_ids = {o.trip_id for o in orders}
    trips_by_id = {
        t.id: t
        for t in db.query(Trip)
        .options(selectinload(Trip.shares))
        .filter(Trip.id.in_(trip_ids))
        .all()
    }

    count = 0
    for order in orders:
        departure_time = _extract_departure_time(order.flight_offer)
        if not departure_time:
            continue
        if not (window_start <= departure_time <= window_end):
            continue

        trip = trips_by_id.get(order.trip_id)
        if not trip:
            continue

        flight_info = _extract_flight_info(order)

        recipients = NotificationService._get_trip_recipients(trip)
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

            locale = DeviceTokenService.get_locale_for_user(db, uid)
            data = {
                "screen": "tripHome",
                "tripId": str(trip.id),
                "orderId": str(order.id),
            }
            context: dict[str, object] = {
                "trip_title": trip.title or untitled_trip(locale),
                "ticket_suffix": "",
                "gate_suffix": "",
            }

            if notif_type == NotificationType.FLIGHT_H4 and flight_info.get("ticket_url"):
                data["ticketUrl"] = flight_info["ticket_url"]
                context["ticket_suffix"] = flight_ticket_suffix(locale, flight_info["ticket_url"])

            if notif_type == NotificationType.FLIGHT_H1 and flight_info.get("terminal_gate"):
                context["gate_suffix"] = flight_gate_suffix(locale, flight_info["terminal_gate"])

            NotificationService.send_localized(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=notif_type,
                context=context,
                data=data,
                locale=locale,
            )
            count += 1
    return count


def _extract_departure_time(offer: FlightOffer | None) -> datetime | None:
    """Parse departure time from a pre-loaded FlightOffer.offer_json, in UTC.

    Amadeus expresses ``departure.at`` in the **local time of the departure
    airport** and frequently omits the UTC offset. Forcing ``tzinfo=UTC`` on a
    naive local value shifts every reminder by the airport's offset (e.g. H-4
    instead of H-1 from Paris). We therefore localize a naive value with the
    departure airport's IANA timezone (resolved offline via airportsdata) before
    converting to UTC. When the string already carries an offset we trust it.
    """
    try:
        if not offer or not offer.offer_json:
            return None
        itineraries = offer.offer_json.get("itineraries", [])
        if not itineraries:
            return None
        segments = itineraries[0].get("segments", [])
        if not segments:
            return None
        departure = segments[0].get("departure", {})
        dep_str = departure.get("at")
        if not dep_str:
            return None
        parsed = datetime.fromisoformat(dep_str)
        if parsed.tzinfo is None:
            tz = _safe_zone(aviation_data_service.timezone_for_iata(departure.get("iataCode")))
            parsed = parsed.replace(tzinfo=tz)
        return parsed.astimezone(UTC)
    except (ValueError, TypeError, KeyError, AttributeError):
        pass
    return None


def _extract_flight_info(order: FlightOrder) -> dict:
    """Extract flight details (ticket_url, terminal) from a pre-loaded order."""
    info: dict = {}

    if order.ticket_url:
        info["ticket_url"] = order.ticket_url

    try:
        offer = order.flight_offer
        if offer and offer.offer_json:
            itineraries = offer.offer_json.get("itineraries", [])
            if itineraries:
                segments = itineraries[0].get("segments", [])
                if segments:
                    terminal = segments[0].get("departure", {}).get("terminal")
                    if terminal:
                        info["terminal_gate"] = f"Terminal {terminal}"
    except (TypeError, KeyError, AttributeError):
        pass

    return info


def _check_morning_summary(db: Session) -> int:
    """Trip ONGOING, activities today, 07:00–10:00 destination-local → MORNING_SUMMARY."""
    now_utc = datetime.now(UTC)
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
        # Fire in the destination's morning, not a fixed UTC hour. The 3h
        # window + the 20h _already_sent dedup absorb the job's ~30min drift.
        local_now = now_utc.astimezone(_safe_zone(trip.destination_timezone))
        if not (7 <= local_now.hour < 10):
            continue
        today_local = local_now.date()

        activities = (
            db.query(Activity)
            .filter(Activity.trip_id == trip.id, Activity.date == today_local)
            .all()
        )
        if not activities:
            continue

        recipients = NotificationService._get_trip_recipients(trip)
        for uid in recipients:
            if NotificationService._already_sent(
                db, uid, trip.id, NotificationType.MORNING_SUMMARY, timedelta(hours=20)
            ):
                continue

            activity_names = ", ".join(a.title for a in activities[:3])
            if len(activities) > 3:
                activity_names += f" (+{len(activities) - 3})"

            locale = DeviceTokenService.get_locale_for_user(db, uid)
            NotificationService.send_localized(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.MORNING_SUMMARY,
                context={
                    "trip_title": trip.title or untitled_trip(locale),
                    "count": len(activities),
                    "activity_names": activity_names,
                },
                data={"screen": "activities", "tripId": str(trip.id)},
                locale=locale,
            )
            count += 1
    return count


def _check_activity_reminders(db: Session) -> int:
    """Activity today, start_time in 30min–1h30 → ACTIVITY_H1."""
    now = datetime.now(UTC)
    today = date.today()
    window_start = (now + timedelta(minutes=30)).time()
    window_end = (now + timedelta(minutes=90)).time()

    # Eager-load the parent trip + its shares so neither the trip lookup nor
    # the recipient resolution issues a query per activity.
    activities = (
        db.query(Activity)
        .options(selectinload(Activity.trip).selectinload(Trip.shares))
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
        trip = activity.trip
        if not trip:
            continue

        recipients = NotificationService._get_trip_recipients(trip)
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
            locale = DeviceTokenService.get_locale_for_user(db, uid)
            location_suffix = (
                activity_location_suffix(locale, activity.location) if activity.location else ""
            )
            NotificationService.send_localized(
                db=db,
                user_id=uid,
                trip_id=trip.id,
                notif_type=NotificationType.ACTIVITY_H1,
                context={
                    "activity_title": activity.title,
                    "location_suffix": location_suffix,
                },
                data={
                    "screen": "activities",
                    "tripId": str(trip.id),
                    "activityId": str(activity.id),
                },
                locale=locale,
            )
            count += 1
    return count


def run_notification_checks() -> dict[str, int]:
    """Open a DB session and run all notification checks (sync)."""
    db = SessionLocal()
    try:
        results = {
            "departure_reminders": _check_departure_reminders(db),
            "flight_h4": _check_flight_alerts(db, 4, NotificationType.FLIGHT_H4),
            "flight_h1": _check_flight_alerts(db, 1, NotificationType.FLIGHT_H1),
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
