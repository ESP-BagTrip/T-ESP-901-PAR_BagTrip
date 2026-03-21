"""Modèle Feedback SQLAlchemy."""

import uuid

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class Feedback(Base):
    """Modèle Feedback — avis utilisateur sur un trip terminé."""

    __tablename__ = "feedbacks"
    __table_args__ = (
        UniqueConstraint("trip_id", "user_id", name="uq_feedbacks_trip_user"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    overall_rating = Column(Integer, nullable=False)
    highlights = Column(Text, nullable=True)
    lowlights = Column(Text, nullable=True)
    would_recommend = Column(Boolean, nullable=False)
    ai_experience_rating = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    trip = relationship("Trip", back_populates="feedbacks")
    user = relationship("User")
