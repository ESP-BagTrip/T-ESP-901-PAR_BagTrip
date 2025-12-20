"""Modèle HotelSearch SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class HotelSearch(Base):
    """Modèle HotelSearch selon PLAN.md."""

    __tablename__ = "hotel_searches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    city_code = Column(String(3), nullable=True)
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    check_in = Column(Date, nullable=False)
    check_out = Column(Date, nullable=False)
    adults = Column(Integer, nullable=False)
    room_qty = Column(Integer, nullable=False)
    currency = Column(String(3), nullable=True)
    amadeus_request = Column(JSON, nullable=False)
    amadeus_response = Column(JSON, nullable=True)
    amadeus_response_received_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    trip = relationship("Trip", back_populates="hotel_searches")
    offers = relationship("HotelOffer", back_populates="hotel_search", cascade="all, delete-orphan")
