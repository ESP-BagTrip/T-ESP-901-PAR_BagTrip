"""Modèle ManualFlight SQLAlchemy."""

import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class ManualFlight(Base):
    """Modèle ManualFlight pour les vols manuels d'un trip."""

    __tablename__ = "manual_flights"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    flight_number = Column(String, nullable=False)
    airline = Column(String, nullable=True)
    departure_airport = Column(String, nullable=True)
    arrival_airport = Column(String, nullable=True)
    departure_date = Column(DateTime(timezone=True), nullable=True)
    arrival_date = Column(DateTime(timezone=True), nullable=True)
    price = Column(Numeric(12, 2), nullable=True)
    currency = Column(String, nullable=True, default="EUR")
    notes = Column(String, nullable=True)
    flight_type = Column(String, nullable=False, default="MAIN")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    trip = relationship("Trip", back_populates="manual_flights")
