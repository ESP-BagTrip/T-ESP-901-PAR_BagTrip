"""Modèle Trip SQLAlchemy."""

import uuid

from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base
from src.enums import TripStatus


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
    status = Column(String, nullable=False, server_default="DRAFT", default=TripStatus.DRAFT)
    description = Column(String, nullable=True)
    budget_total = Column(Numeric(12, 2), nullable=True)
    origin = Column(String, nullable=True, default="MANUAL")
    cover_image_url = Column(String, nullable=True)
    destination_name = Column(String, nullable=True)
    nb_travelers = Column(Integer, nullable=True, default=1)
    archived_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    travelers = relationship("TripTraveler", back_populates="trip", cascade="all, delete-orphan")
    accommodations = relationship(
        "Accommodation", back_populates="trip", cascade="all, delete-orphan"
    )
    baggage_items = relationship(
        "BaggageItem", back_populates="trip", cascade="all, delete-orphan"
    )
    flight_searches = relationship(
        "FlightSearch", back_populates="trip", cascade="all, delete-orphan"
    )
    booking_intents = relationship(
        "BookingIntent", back_populates="trip", cascade="all, delete-orphan"
    )
    shares = relationship("TripShare", back_populates="trip", cascade="all, delete-orphan")
    activities = relationship("Activity", back_populates="trip", cascade="all, delete-orphan")
    budget_items = relationship("BudgetItem", back_populates="trip", cascade="all, delete-orphan")
    feedbacks = relationship("Feedback", back_populates="trip", cascade="all, delete-orphan")
