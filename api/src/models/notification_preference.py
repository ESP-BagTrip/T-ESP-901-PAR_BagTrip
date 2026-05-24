"""Modèle NotificationPreference SQLAlchemy."""

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.user import User


class NotificationPreference(Base):
    """Préférences de notifications d'un utilisateur.

    Une ligne par utilisateur (PK = user_id). Tous les flags sont vrais par
    défaut : l'absence de ligne équivaut donc à "tout activé". ``push_enabled``
    est le master switch — quand il est faux, aucune notification (hors ADMIN
    système) n'est dispatchée.
    """

    __tablename__ = "notification_preferences"

    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    push_enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=func.true())
    flight_reminders: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=func.true()
    )
    activity_reminders: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=func.true()
    )
    trip_updates: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=func.true())
    budget_alerts: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=func.true())
    social: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=func.true())
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship("User")
