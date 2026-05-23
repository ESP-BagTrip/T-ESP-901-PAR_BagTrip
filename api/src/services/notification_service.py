"""Service pour la gestion des notifications push."""

from datetime import UTC, datetime, timedelta
from math import ceil
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import NotificationType
from src.models.notification import Notification
from src.models.trip import Trip
from src.services.budget_item_service import BudgetItemService
from src.services.device_token_service import DeviceTokenService
from src.services.notification_messages import render_notification, untitled_trip
from src.services.notification_preference_service import NotificationPreferenceService
from src.utils.logger import logger

TAG = "[NOTIFICATION]"


class NotificationService:
    """Service pour les notifications push (FCM)."""

    @staticmethod
    def create_and_send(
        db: Session,
        user_id: UUID,
        trip_id: UUID | None,
        notif_type: str,
        title: str,
        body: str,
        data: dict | None = None,
    ) -> Notification:
        """Create a notification in DB and send via FCM."""
        notif = Notification(
            user_id=user_id,
            trip_id=trip_id,
            type=notif_type,
            title=title,
            body=body,
            data=data,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)

        # Send push
        tokens_map = DeviceTokenService.get_tokens_for_users(db, [user_id])
        tokens = tokens_map.get(user_id, [])
        if tokens:
            sent = NotificationService._send_fcm(db, tokens, title, body, data)
            if sent:
                notif.sent_at = datetime.now(UTC)
                db.commit()

        return notif

    @staticmethod
    def create_and_send_bulk(
        db: Session,
        user_ids: list[UUID],
        trip_id: UUID | None,
        notif_type: str,
        title: str,
        body: str,
        data: dict | None = None,
    ) -> list[Notification]:
        """Create notifications for multiple users and send via FCM."""
        notifs = []
        for uid in user_ids:
            notif = Notification(
                user_id=uid,
                trip_id=trip_id,
                type=notif_type,
                title=title,
                body=body,
                data=data,
            )
            db.add(notif)
            notifs.append(notif)
        db.commit()
        for n in notifs:
            db.refresh(n)

        # Send push to all
        tokens_map = DeviceTokenService.get_tokens_for_users(db, user_ids)
        all_tokens = [t for tlist in tokens_map.values() for t in tlist]
        if all_tokens:
            sent = NotificationService._send_fcm(db, all_tokens, title, body, data)
            if sent:
                now = datetime.now(UTC)
                for n in notifs:
                    n.sent_at = now
                db.commit()

        return notifs

    @staticmethod
    def send_localized(
        db: Session,
        *,
        user_id: UUID,
        trip_id: UUID | None,
        notif_type: str,
        notif_key: str | None = None,
        context: dict | None = None,
        data: dict | None = None,
        locale: str | None = None,
    ) -> Notification | None:
        """Render a localized notification for one user and dispatch it.

        Resolves the recipient's locale from their most recent device token
        (unless ``locale`` is provided), renders title/body from the i18n
        catalogue, then persists + pushes via :meth:`create_and_send`.

        ``notif_key`` defaults to ``notif_type`` — pass it explicitly only when
        the catalogue key differs from the persisted type (e.g. budget alerts).

        Returns ``None`` (creating + sending nothing) when the recipient has
        disabled this notification category in their preferences.
        """
        if not NotificationPreferenceService.is_type_enabled(db, user_id, notif_type):
            return None
        resolved = locale or DeviceTokenService.get_locale_for_user(db, user_id)
        title, body = render_notification(notif_key or notif_type, resolved, **(context or {}))
        return NotificationService.create_and_send(
            db=db,
            user_id=user_id,
            trip_id=trip_id,
            notif_type=notif_type,
            title=title,
            body=body,
            data=data,
        )

    @staticmethod
    def get_for_user(
        db: Session, user_id: UUID, page: int = 1, limit: int = 20
    ) -> tuple[list[Notification], int, int, int]:
        """Get paginated notifications for a user. Returns (items, total, total_pages, unread_count)."""
        query = (
            db.query(Notification)
            .filter(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
        )
        total = query.count()
        total_pages = ceil(total / limit) if limit > 0 else 0
        items = query.offset((page - 1) * limit).limit(limit).all()
        unread_count = (
            db.query(Notification)
            .filter(Notification.user_id == user_id, Notification.is_read.is_(False))
            .count()
        )
        return items, total, total_pages, unread_count

    @staticmethod
    def get_unread_count(db: Session, user_id: UUID) -> int:
        """Get unread notification count."""
        return (
            db.query(Notification)
            .filter(Notification.user_id == user_id, Notification.is_read.is_(False))
            .count()
        )

    @staticmethod
    def mark_as_read(db: Session, notification_id: UUID, user_id: UUID) -> Notification | None:
        """Mark a single notification as read."""
        notif = (
            db.query(Notification)
            .filter(Notification.id == notification_id, Notification.user_id == user_id)
            .first()
        )
        if notif:
            notif.is_read = True
            db.commit()
            db.refresh(notif)
        return notif

    # Only retry pushes that failed recently — past this window we assume the
    # device is genuinely unreachable (uninstalled, token rotated) and stop
    # re-attempting so the scheduler doesn't hammer FCM forever. With a 30-min
    # tick this bounds retries to ~4 attempts without needing a retry-count
    # column.
    RETRY_WINDOW_MINUTES = 120

    @staticmethod
    def retry_unsent(db: Session, window_minutes: int = RETRY_WINDOW_MINUTES) -> int:
        """Re-attempt FCM delivery for notifications stuck with ``sent_at IS NULL``.

        Picks up rows whose initial push failed (transient network/timeout) and
        were created inside the retry window, then retries the FCM send and
        stamps ``sent_at`` on success. Returns the number successfully sent.

        FCM is at-least-once: a push that actually arrived but timed out on our
        side may be re-sent. That's acceptable for notifications and matches the
        provider's own retry semantics.
        """
        cutoff = datetime.now(UTC) - timedelta(minutes=window_minutes)
        pending = (
            db.query(Notification)
            .filter(Notification.sent_at.is_(None), Notification.created_at >= cutoff)
            .all()
        )
        if not pending:
            return 0

        user_ids = list({n.user_id for n in pending})
        tokens_map = DeviceTokenService.get_tokens_for_users(db, user_ids)

        sent_count = 0
        now = datetime.now(UTC)
        for notif in pending:
            tokens = tokens_map.get(notif.user_id, [])
            if not tokens:
                continue
            if NotificationService._send_fcm(db, tokens, notif.title, notif.body, notif.data):
                notif.sent_at = now
                sent_count += 1
        if sent_count:
            db.commit()
        return sent_count

    @staticmethod
    def delete(db: Session, notification_id: UUID, user_id: UUID) -> bool:
        """Delete a single notification owned by the user. Returns True if removed."""
        notif = (
            db.query(Notification)
            .filter(Notification.id == notification_id, Notification.user_id == user_id)
            .first()
        )
        if not notif:
            return False
        db.delete(notif)
        db.commit()
        return True

    @staticmethod
    def mark_all_as_read(db: Session, user_id: UUID) -> int:
        """Mark all notifications as read for a user. Returns count updated."""
        from sqlalchemy import update

        result = db.execute(
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read.is_(False))
            .values(is_read=True)
        )
        db.commit()
        return result.rowcount

    @staticmethod
    def check_and_send_budget_alert(db: Session, trip: Trip) -> None:
        """Check budget summary and send alert if threshold crossed."""
        try:
            summary = BudgetItemService.get_budget_summary(db, trip)
            alert_level = summary.get("alert_level")
            if not alert_level:
                return

            # Dedup on the persisted type (BUDGET_ALERT) + the alertLevel kept
            # in the JSON payload, so a WARNING doesn't suppress an EXCEEDED.
            if NotificationService._already_sent(
                db,
                trip.user_id,
                trip.id,
                NotificationType.BUDGET_ALERT,
                timedelta(hours=1),
                data_key="alertLevel",
                data_value=alert_level,
            ):
                return

            notif_key = (
                "BUDGET_ALERT_WARNING" if alert_level == "WARNING" else "BUDGET_ALERT_EXCEEDED"
            )
            pct = summary.get("percent_consumed", 0)
            locale = DeviceTokenService.get_locale_for_user(db, trip.user_id)
            trip_title = trip.title or untitled_trip(locale)

            NotificationService.send_localized(
                db=db,
                user_id=trip.user_id,
                trip_id=trip.id,
                notif_type=NotificationType.BUDGET_ALERT,
                notif_key=notif_key,
                context={"pct": f"{pct:.0f}", "trip_title": trip_title},
                data={"screen": "budget", "tripId": str(trip.id), "alertLevel": alert_level},
                locale=locale,
            )
        except Exception as e:
            logger.error(f"{TAG} Budget alert check failed for trip {trip.id}: {e}")

    @staticmethod
    def _get_trip_recipients(trip: Trip, owner_only: bool = False) -> list[UUID]:
        """Get owner + viewers for a trip via the ``trip.shares`` relationship.

        Reads the relationship rather than issuing its own query — callers that
        already ``selectinload(Trip.shares)`` (the notification job) pay zero
        extra queries; others trigger a single lazy load.
        """
        recipients = [trip.user_id]
        if not owner_only:
            for share in trip.shares:
                if share.user_id not in recipients:
                    recipients.append(share.user_id)
        return recipients

    @staticmethod
    def _send_fcm(
        db: Session, tokens: list[str], title: str, body: str, data: dict | None = None
    ) -> bool:
        """Send push notification via Firebase Cloud Messaging."""
        try:
            from firebase_admin import messaging

            from src.integrations.firebase import get_firebase_app

            if not get_firebase_app():
                logger.warn(f"{TAG} Firebase not initialized — skipping push")
                return False

            notification = messaging.Notification(title=title, body=body)
            str_data = {k: str(v) for k, v in data.items()} if data else None

            if len(tokens) == 1:
                message = messaging.Message(
                    notification=notification,
                    data=str_data,
                    token=tokens[0],
                )
                try:
                    messaging.send(message)
                except messaging.UnregisteredError:
                    # Dead token — drop it so it stops accumulating. The
                    # multicast path already does this; mirror it here.
                    from src.models.device_token import DeviceToken

                    db.query(DeviceToken).filter(DeviceToken.fcm_token == tokens[0]).delete(
                        synchronize_session="fetch"
                    )
                    db.commit()
                    return False
            else:
                message = messaging.MulticastMessage(
                    notification=notification,
                    data=str_data,
                    tokens=tokens,
                )
                response = messaging.send_each_for_multicast(message)
                # Clean up invalid tokens
                if response.failure_count > 0:
                    for i, send_response in enumerate(response.responses):
                        if send_response.exception and isinstance(
                            send_response.exception, messaging.UnregisteredError
                        ):
                            from src.models.device_token import DeviceToken

                            db.query(DeviceToken).filter(DeviceToken.fcm_token == tokens[i]).delete(
                                synchronize_session="fetch"
                            )
                    db.commit()

            return True
        except Exception as e:
            logger.error(f"{TAG} FCM send failed: {e}")
            return False

    @staticmethod
    def _already_sent(
        db: Session,
        user_id: UUID,
        trip_id: UUID | None,
        notif_type: str,
        since: timedelta,
        data_key: str | None = None,
        data_value: str | None = None,
    ) -> bool:
        """Check deduplication — was this notification type already sent recently?"""
        cutoff = datetime.now(UTC) - since
        query = db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.type == notif_type,
            Notification.created_at >= cutoff,
        )
        if trip_id:
            query = query.filter(Notification.trip_id == trip_id)
        if data_key and data_value:
            query = query.filter(Notification.data[data_key].astext == data_value)
        return query.first() is not None
