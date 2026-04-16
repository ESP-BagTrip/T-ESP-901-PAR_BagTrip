"""Modèle TripShare SQLAlchemy."""

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


class TripShare(Base):
    """Modèle TripShare — partage d'un trip avec un autre utilisateur."""

    __tablename__ = "trip_shares"
    __table_args__ = (UniqueConstraint("trip_id", "user_id", name="uq_trip_shares_trip_user"),)

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    role: Mapped[str] = mapped_column(String, nullable=False, default="VIEWER")
    invited_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip", back_populates="shares")
    user: Mapped["User"] = relationship("User")
