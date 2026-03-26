"""Modèle TripShare SQLAlchemy."""

import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class TripShare(Base):
    """Modèle TripShare — partage d'un trip avec un autre utilisateur."""

    __tablename__ = "trip_shares"
    __table_args__ = (UniqueConstraint("trip_id", "user_id", name="uq_trip_shares_trip_user"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    role = Column(String, nullable=False, default="VIEWER")
    invited_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    trip = relationship("Trip", back_populates="shares")
    user = relationship("User")
