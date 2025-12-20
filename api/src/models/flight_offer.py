"""Modèle FlightOffer SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class FlightOffer(Base):
    """Modèle FlightOffer selon PLAN.md."""

    __tablename__ = "flight_offers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flight_search_id = Column(
        UUID(as_uuid=True), ForeignKey("flight_searches.id"), nullable=False, index=True
    )
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    amadeus_offer_id = Column(String, nullable=True)
    source = Column(String, nullable=True)
    validating_airline_codes = Column(String, nullable=True)
    last_ticketing_datetime = Column(DateTime(timezone=True), nullable=True)
    currency = Column(String(3), nullable=True)
    grand_total = Column(Numeric(10, 2), nullable=True)
    base_total = Column(Numeric(10, 2), nullable=True)
    offer_json = Column(JSON, nullable=False)  # Full Amadeus offer
    priced_offer_json = Column(JSON, nullable=True)  # Priced offer if repriced
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    flight_search = relationship("FlightSearch", back_populates="offers")
    orders = relationship("FlightOrder", back_populates="flight_offer")
