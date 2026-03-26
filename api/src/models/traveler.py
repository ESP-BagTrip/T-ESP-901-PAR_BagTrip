"""Modèle TripTraveler SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, Date, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class TripTraveler(Base):
    """Modèle TripTraveler selon PLAN.md."""

    __tablename__ = "trip_travelers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    amadeus_traveler_ref = Column(String, nullable=True)
    traveler_type = Column(String, nullable=False)  # ADULT | CHILD | etc.
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(String, nullable=True)
    documents = Column(JSON, nullable=True)
    contacts = Column(JSON, nullable=True)
    raw = Column(JSON, nullable=True)  # Full Amadeus payload
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    trip = relationship("Trip", back_populates="travelers")
