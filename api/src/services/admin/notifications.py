"""Admin service — notifications domain."""

from sqlalchemy.orm import Session

from src.api.common.pagination import PaginationParams, paginate
from src.models.notification import Notification
from src.models.trip import Trip
from src.models.user import User


def _serialize_notification_row(row) -> dict:
    notif, user_email, trip_title = row
    return {
        "id": notif.id,
        "user_id": notif.user_id,
        "user_email": user_email,
        "trip_id": notif.trip_id,
        "trip_title": trip_title,
        "type": notif.type,
        "title": notif.title,
        "body": notif.body,
        "is_read": notif.is_read,
        "sent_at": notif.sent_at,
        "created_at": notif.created_at,
    }


class AdminNotificationsService:
    """Admin operations over notifications."""

    @staticmethod
    def get_all_notifications(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour toutes les notifications."""
        query = (
            db.query(
                Notification,
                User.email.label("user_email"),
                Trip.title.label("trip_title"),
            )
            .join(User, Notification.user_id == User.id)
            .outerjoin(Trip, Notification.trip_id == Trip.id)
            .order_by(Notification.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_notification_row
        ).as_tuple()
