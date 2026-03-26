"""Modèle BookingIntent SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class BookingIntent(Base):
    """Modèle BookingIntent selon PLAN.md - Clé de voûte de l'orchestration."""

    __tablename__ = "booking_intents"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)

    type = Column(String, nullable=False)  # flight
    status = Column(
        String, nullable=False, index=True
    )  # INIT | AUTHORIZED | BOOKING_PENDING | BOOKED | CAPTURED | FAILED | CANCELLED | PAYMENT_CAPTURE_FAILED

    amount = Column(Numeric(10, 2), nullable=False)  # In minor units (cents) in code, decimal in DB
    currency = Column(String(3), nullable=False)

    selected_offer_type = Column(String, nullable=True)  # flight_offer
    selected_offer_id = Column(UUID(as_uuid=True), nullable=True)  # flight_offers.id
    selected_offer_payload_hash = Column(String, nullable=True)

    stripe_payment_intent_id = Column(String, nullable=True)
    stripe_charge_id = Column(String, nullable=True)

    amadeus_order_id = Column(String, nullable=True)  # flight
    last_error = Column(JSON, nullable=True)
    raw = Column(JSON, nullable=True)  # metadata / idempotency keys / etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    trip = relationship("Trip", back_populates="booking_intents")
    flight_order = relationship("FlightOrder", back_populates="booking_intent", uselist=False)
    stripe_events = relationship("StripeEvent", back_populates="booking_intent")
