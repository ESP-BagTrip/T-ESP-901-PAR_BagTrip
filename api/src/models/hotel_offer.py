"""Modèle HotelOffer SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class HotelOffer(Base):
    """Modèle HotelOffer selon PLAN.md."""

    __tablename__ = "hotel_offers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    hotel_search_id = Column(
        UUID(as_uuid=True), ForeignKey("hotel_searches.id"), nullable=False, index=True
    )
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    hotel_id = Column(String, nullable=True)
    offer_id = Column(String, nullable=True)
    chain_code = Column(String, nullable=True)
    room_type = Column(String, nullable=True)
    currency = Column(String(3), nullable=True)
    total_price = Column(Numeric(10, 2), nullable=True)
    offer_json = Column(JSON, nullable=False)  # Full Amadeus offer
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    hotel_search = relationship("HotelSearch", back_populates="offers")
    bookings = relationship("HotelBooking", back_populates="hotel_offer")
