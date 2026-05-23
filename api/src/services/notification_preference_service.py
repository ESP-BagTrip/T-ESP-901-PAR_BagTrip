"""Service pour les préférences de notifications par utilisateur."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import NotificationType
from src.models.notification_preference import NotificationPreference

# Mapping type de notification -> attribut "catégorie" sur NotificationPreference.
# ADMIN est absent volontairement : c'est une notification système non
# désactivable (toujours dispatchée).
_TYPE_TO_CATEGORY: dict[str, str] = {
    NotificationType.DEPARTURE_REMINDER: "flight_reminders",
    NotificationType.FLIGHT_H4: "flight_reminders",
    NotificationType.FLIGHT_H1: "flight_reminders",
    NotificationType.ACTIVITY_H1: "activity_reminders",
    NotificationType.MORNING_SUMMARY: "trip_updates",
    NotificationType.TRIP_STARTED: "trip_updates",
    NotificationType.TRIP_ENDED: "trip_updates",
    NotificationType.BUDGET_ALERT: "budget_alerts",
    NotificationType.TRIP_SHARED: "social",
}

# Champs booléens modifiables via update().
_BOOL_FIELDS = (
    "push_enabled",
    "flight_reminders",
    "activity_reminders",
    "trip_updates",
    "budget_alerts",
    "social",
)


class NotificationPreferenceService:
    """CRUD + gating des préférences de notifications."""

    @staticmethod
    def get_or_create(db: Session, user_id: UUID) -> NotificationPreference:
        """Retourne les préférences de l'utilisateur, en créant la ligne par
        défaut (tout activé) si elle n'existe pas encore."""
        pref = (
            db.query(NotificationPreference)
            .filter(NotificationPreference.user_id == user_id)
            .first()
        )
        if pref is None:
            pref = NotificationPreference(user_id=user_id)
            db.add(pref)
            db.commit()
            db.refresh(pref)
        return pref

    @staticmethod
    def update(db: Session, user_id: UUID, **fields: bool) -> NotificationPreference:
        """Met à jour partiellement les préférences (upsert).

        Seuls les champs booléens connus sont appliqués ; les valeurs ``None``
        (champ omis dans la requête PATCH) sont ignorées.
        """
        pref = NotificationPreferenceService.get_or_create(db, user_id)
        for key in _BOOL_FIELDS:
            value = fields.get(key)
            if value is not None:
                setattr(pref, key, value)
        db.commit()
        db.refresh(pref)
        return pref

    @staticmethod
    def is_type_enabled(db: Session, user_id: UUID, notif_type: str) -> bool:
        """Indique si une notification de ce type doit être dispatchée.

        - ADMIN (et tout type non mappé) : toujours True (système).
        - Pas de ligne de préférences : tout activé (defaults).
        - ``push_enabled`` à False : master switch off -> False.
        - Sinon : valeur du flag de la catégorie correspondante.
        """
        category = _TYPE_TO_CATEGORY.get(notif_type)
        if category is None:
            # ADMIN ou type inconnu -> non désactivable.
            return True

        pref = (
            db.query(NotificationPreference)
            .filter(NotificationPreference.user_id == user_id)
            .first()
        )
        if pref is None:
            return True
        if not pref.push_enabled:
            return False
        return bool(getattr(pref, category))
