"""Modèle FlightOrder SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class FlightOrder(Base):
    """Modèle FlightOrder selon PLAN.md."""

    __tablename__ = "flight_orders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    flight_offer_id = Column(UUID(as_uuid=True), ForeignKey("flight_offers.id"), nullable=False)
    booking_intent_id = Column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True, unique=True
    )
    amadeus_flight_order_id = Column(String, nullable=True, unique=True)
    status = Column(String, nullable=True)
    booking_reference = Column(String, nullable=True)
    amadeus_create_order_request = Column(JSON, nullable=False)
    payment_id = Column(String, nullable=True)
    ticket_url = Column(String, nullable=True)
    amadeus_create_order_response = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    flight_offer = relationship("FlightOffer", back_populates="orders")
    booking_intent = relationship("BookingIntent", back_populates="flight_order", uselist=False)
