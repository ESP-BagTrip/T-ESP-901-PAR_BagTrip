"""Service pour la gestion des notifications push."""

from datetime import timezone, datetime, timedelta
from math import ceil
from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import NotificationType
from src.models.notification import Notification
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.services.budget_item_service import BudgetItemService
from src.services.device_token_service import DeviceTokenService
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
                notif.sent_at = datetime.now(timezone.utc)
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
                now = datetime.now(timezone.utc)
                for n in notifs:
                    n.sent_at = now
                db.commit()

        return notifs

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

            # Check if already sent at this level
            if NotificationService._already_sent(
                db, trip.user_id, trip.id, f"BUDGET_ALERT_{alert_level}", timedelta(hours=1)
            ):
                return

            title = "Alerte budget" if alert_level == "WARNING" else "Budget dépassé !"
            pct = summary.get("percent_consumed", 0)
            body = (
                f"Vous avez utilisé {pct:.0f}% du budget pour « {trip.title or 'votre voyage'} »."
            )

            NotificationService.create_and_send(
                db=db,
                user_id=trip.user_id,
                trip_id=trip.id,
                notif_type=NotificationType.BUDGET_ALERT,
                title=title,
                body=body,
                data={"screen": "budget", "tripId": str(trip.id), "alertLevel": alert_level},
            )
        except Exception as e:
            logger.error(f"{TAG} Budget alert check failed for trip {trip.id}: {e}")

    @staticmethod
    def _get_trip_recipients(db: Session, trip: Trip, owner_only: bool = False) -> list[UUID]:
        """Get owner + viewers for a trip via TripShare."""
        recipients = [trip.user_id]
        if not owner_only:
            viewers = db.query(TripShare.user_id).filter(TripShare.trip_id == trip.id).all()
            for (uid,) in viewers:
                if uid not in recipients:
                    recipients.append(uid)
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
                messaging.send(message)
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
        cutoff = datetime.now(timezone.utc) - since
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
