"""Modèle Booking SQLAlchemy."""

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import JSON, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class Booking(Base):
    """Modèle Booking pour stocker les réservations de vols."""

    __tablename__ = "bookings"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    amadeus_order_id: Mapped[str] = mapped_column(String, nullable=False)
    flight_offers: Mapped[dict] = mapped_column(JSON, nullable=False)
    status: Mapped[str] = mapped_column(
        String, nullable=False, default="CONFIRMED"
    )  # PENDING, CONFIRMED, CANCELLED
    price_total: Mapped[float] = mapped_column(Float, nullable=False)
    currency: Mapped[str] = mapped_column(String, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        "createdAt", DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        "updatedAt",
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
