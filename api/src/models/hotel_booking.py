"""Modèle HotelBooking SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class HotelBooking(Base):
    """Modèle HotelBooking selon PLAN.md."""

    __tablename__ = "hotel_bookings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    hotel_offer_id = Column(UUID(as_uuid=True), ForeignKey("hotel_offers.id"), nullable=False)
    booking_intent_id = Column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True, unique=True
    )
    amadeus_booking_id = Column(String, nullable=True, unique=True)
    status = Column(String, nullable=True)
    amadeus_booking_request = Column(JSON, nullable=False)
    amadeus_booking_response = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    hotel_offer = relationship("HotelOffer", back_populates="bookings")
    booking_intent = relationship("BookingIntent", back_populates="hotel_booking", uselist=False)
