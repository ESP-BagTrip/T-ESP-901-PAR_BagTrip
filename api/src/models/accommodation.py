"""Modèle Accommodation SQLAlchemy."""

import uuid

from sqlalchemy import Column, Date, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class Accommodation(Base):
    """Modèle Accommodation pour les hébergements d'un trip."""

    __tablename__ = "accommodations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    address = Column(String, nullable=True)
    check_in = Column(Date, nullable=True)
    check_out = Column(Date, nullable=True)
    price_per_night = Column(Numeric(12, 2), nullable=True)
    currency = Column(String(3), nullable=True, default="EUR")
    booking_reference = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    trip = relationship("Trip", back_populates="accommodations")
