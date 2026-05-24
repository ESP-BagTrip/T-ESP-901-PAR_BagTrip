"""Modèle BookingIntent SQLAlchemy."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import JSON, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.flight_order import FlightOrder
    from src.models.stripe_event import StripeEvent
    from src.models.trip import Trip


class BookingIntent(Base):
    """Modèle BookingIntent selon PLAN.md - Clé de voûte de l'orchestration."""

    __tablename__ = "booking_intents"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )

    type: Mapped[str] = mapped_column(String, nullable=False)  # flight
    status: Mapped[str] = mapped_column(
        String, nullable=False, index=True
    )  # INIT | AUTHORIZED | BOOKING_PENDING | BOOKED | CAPTURED | FAILED | CANCELLED | PAYMENT_CAPTURE_FAILED

    amount: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False
    )  # In minor units (cents) in code, decimal in DB
    currency: Mapped[str] = mapped_column(String(3), nullable=False)

    selected_offer_type: Mapped[str | None] = mapped_column(String, nullable=True)  # flight_offer
    selected_offer_id: Mapped[_UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )  # flight_offers.id
    selected_offer_payload_hash: Mapped[str | None] = mapped_column(String, nullable=True)

    stripe_payment_intent_id: Mapped[str | None] = mapped_column(String, nullable=True)
    stripe_charge_id: Mapped[str | None] = mapped_column(String, nullable=True)

    amadeus_order_id: Mapped[str | None] = mapped_column(String, nullable=True)  # flight
    last_error: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    raw: Mapped[dict | None] = mapped_column(
        JSON, nullable=True
    )  # metadata / idempotency keys / etc.
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
    trip: Mapped["Trip"] = relationship("Trip", back_populates="booking_intents")
    flight_order: Mapped["FlightOrder | None"] = relationship(
        "FlightOrder", back_populates="booking_intent", uselist=False
    )
    stripe_events: Mapped[list["StripeEvent"]] = relationship(
        "StripeEvent", back_populates="booking_intent"
    )
