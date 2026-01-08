"""Modèle Trip SQLAlchemy."""

import uuid

from sqlalchemy import Column, Date, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class Trip(Base):
    """Modèle Trip selon PLAN.md."""

    __tablename__ = "trips"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String, nullable=True)
    origin_iata = Column(String(3), nullable=True)
    destination_iata = Column(String(3), nullable=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    status = Column(String, nullable=True)  # draft | planned | booked | cancelled
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    travelers = relationship("TripTraveler", back_populates="trip", cascade="all, delete-orphan")
    flight_searches = relationship(
        "FlightSearch", back_populates="trip", cascade="all, delete-orphan"
    )
    hotel_searches = relationship(
        "HotelSearch", back_populates="trip", cascade="all, delete-orphan"
    )
    booking_intents = relationship(
        "BookingIntent", back_populates="trip", cascade="all, delete-orphan"
    )
    conversations = relationship(
        "Conversation", back_populates="trip", cascade="all, delete-orphan"
    )
