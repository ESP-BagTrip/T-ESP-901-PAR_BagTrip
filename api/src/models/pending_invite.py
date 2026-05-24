"""Modèle PendingInvite SQLAlchemy — invitation en attente pour un utilisateur non inscrit."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.trip import Trip
    from src.models.user import User


class PendingInvite(Base):
    """Invitation en attente pour un utilisateur non encore inscrit."""

    __tablename__ = "pending_invites"
    __table_args__ = (UniqueConstraint("trip_id", "email", name="uq_pending_invites_trip_email"),)

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    email: Mapped[str] = mapped_column(String, nullable=False, index=True)
    role: Mapped[str] = mapped_column(String, nullable=False, default="VIEWER")
    token: Mapped[str] = mapped_column(String, nullable=False, unique=True, index=True)
    message: Mapped[str | None] = mapped_column(String, nullable=True)
    invited_by: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    trip: Mapped["Trip"] = relationship("Trip")
    inviter: Mapped["User"] = relationship("User", foreign_keys=[invited_by])
