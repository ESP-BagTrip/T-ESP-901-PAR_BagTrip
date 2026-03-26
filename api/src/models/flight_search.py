"""Modèle FlightSearch SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Boolean, Column, Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class FlightSearch(Base):
    """Modèle FlightSearch selon PLAN.md."""

    __tablename__ = "flight_searches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    origin_iata = Column(String(3), nullable=False)
    destination_iata = Column(String(3), nullable=False)
    departure_date = Column(Date, nullable=False)
    return_date = Column(Date, nullable=True)
    adults = Column(Integer, nullable=False)
    children = Column(Integer, nullable=True)
    infants = Column(Integer, nullable=True)
    travel_class = Column(String, nullable=True)
    non_stop = Column(Boolean, nullable=True)
    currency = Column(String(3), nullable=True)
    amadeus_request = Column(JSON, nullable=False)
    amadeus_response = Column(JSON, nullable=True)
    amadeus_response_received_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    trip = relationship("Trip", back_populates="flight_searches")
    offers = relationship(
        "FlightOffer", back_populates="flight_search", cascade="all, delete-orphan"
    )
