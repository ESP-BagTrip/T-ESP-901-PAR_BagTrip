"""Service pour la gestion des device tokens FCM."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.device_token import DeviceToken
from src.services.notification_messages import normalize_locale


class DeviceTokenService:
    """Service pour les opérations CRUD sur les device tokens."""

    @staticmethod
    def register(
        db: Session,
        user_id: UUID,
        fcm_token: str,
        platform: str | None = None,
        locale: str | None = None,
    ) -> DeviceToken:
        """Register or update a device token (upsert)."""
        existing = db.query(DeviceToken).filter(DeviceToken.fcm_token == fcm_token).first()
        if existing:
            existing.user_id = user_id
            existing.platform = platform
            if locale is not None:
                existing.locale = normalize_locale(locale)
            db.commit()
            db.refresh(existing)
            return existing

        token = DeviceToken(
            user_id=user_id,
            fcm_token=fcm_token,
            platform=platform,
            locale=normalize_locale(locale) if locale is not None else None,
        )
        db.add(token)
        db.commit()
        db.refresh(token)
        return token

    @staticmethod
    def unregister(db: Session, user_id: UUID, fcm_token: str) -> None:
        """Remove a device token."""
        db.query(DeviceToken).filter(
            DeviceToken.user_id == user_id,
            DeviceToken.fcm_token == fcm_token,
        ).delete(synchronize_session="fetch")
        db.commit()

    @staticmethod
    def get_tokens_for_users(db: Session, user_ids: list[UUID]) -> dict[UUID, list[str]]:
        """Get FCM tokens grouped by user ID."""
        if not user_ids:
            return {}
        tokens = (
            db.query(DeviceToken.user_id, DeviceToken.fcm_token)
            .filter(DeviceToken.user_id.in_(user_ids))
            .all()
        )
        result: dict[UUID, list[str]] = {}
        for uid, fcm in tokens:
            result.setdefault(uid, []).append(fcm)
        return result

    @staticmethod
    def get_locale_for_user(db: Session, user_id: UUID) -> str:
        """Resolve a user's notification locale from their most recent device.

        Falls back to ``en`` when the user has no device, or no device with a
        stored locale. Multi-device users with mixed locales resolve to the
        most recently updated token (accepted trade-off).
        """
        token = (
            db.query(DeviceToken)
            .filter(DeviceToken.user_id == user_id)
            .order_by(DeviceToken.updated_at.desc())
            .first()
        )
        if token is not None and isinstance(token.locale, str) and token.locale:
            return normalize_locale(token.locale)
        return "en"
