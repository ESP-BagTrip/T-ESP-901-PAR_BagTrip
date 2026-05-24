"""Modèle Feedback SQLAlchemy."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.trip import Trip
    from src.models.user import User


class Feedback(Base):
    """Modèle Feedback — avis utilisateur sur un trip terminé."""

    __tablename__ = "feedbacks"
    __table_args__ = (UniqueConstraint("trip_id", "user_id", name="uq_feedbacks_trip_user"),)

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    overall_rating: Mapped[int] = mapped_column(Integer, nullable=False)
    highlights: Mapped[str | None] = mapped_column(Text, nullable=True)
    lowlights: Mapped[str | None] = mapped_column(Text, nullable=True)
    would_recommend: Mapped[bool] = mapped_column(Boolean, nullable=False)
    ai_experience_rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip", back_populates="feedbacks")
    user: Mapped["User"] = relationship("User")
