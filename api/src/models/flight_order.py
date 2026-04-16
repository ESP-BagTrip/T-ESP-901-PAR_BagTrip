"""Modèle FlightOrder SQLAlchemy."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import JSON, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.booking_intent import BookingIntent
    from src.models.flight_offer import FlightOffer


class FlightOrder(Base):
    """Modèle FlightOrder selon PLAN.md."""

    __tablename__ = "flight_orders"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    flight_offer_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("flight_offers.id"), nullable=False
    )
    booking_intent_id: Mapped[_UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True, unique=True
    )
    amadeus_flight_order_id: Mapped[str | None] = mapped_column(String, nullable=True, unique=True)
    status: Mapped[str | None] = mapped_column(String, nullable=True)
    booking_reference: Mapped[str | None] = mapped_column(String, nullable=True)
    amadeus_create_order_request: Mapped[dict] = mapped_column(JSON, nullable=False)
    payment_id: Mapped[str | None] = mapped_column(String, nullable=True)
    ticket_url: Mapped[str | None] = mapped_column(String, nullable=True)
    amadeus_create_order_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    flight_offer: Mapped["FlightOffer"] = relationship("FlightOffer", back_populates="orders")
    booking_intent: Mapped["BookingIntent | None"] = relationship(
        "BookingIntent", back_populates="flight_order", uselist=False
    )
