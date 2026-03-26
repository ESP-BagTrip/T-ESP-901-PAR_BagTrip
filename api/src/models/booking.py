"""Modèle Booking SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from src.config.database import Base


class Booking(Base):
    """Modèle Booking pour stocker les réservations de vols."""

    __tablename__ = "bookings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    amadeus_order_id = Column(String, nullable=False)
    flight_offers = Column(JSON, nullable=False)
    status = Column(String, nullable=False, default="CONFIRMED")  # PENDING, CONFIRMED, CANCELLED
    price_total = Column(Float, nullable=False)
    currency = Column(String, nullable=False)

    created_at = Column(
        "createdAt", DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at = Column(
        "updatedAt",
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
