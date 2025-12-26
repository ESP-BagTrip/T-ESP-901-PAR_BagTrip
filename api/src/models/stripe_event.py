"""Modèle StripeEvent SQLAlchemy."""

import uuid

from sqlalchemy import JSON, Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class StripeEvent(Base):
    """Modèle StripeEvent selon PLAN.md."""

    __tablename__ = "stripe_events"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    stripe_event_id = Column(String, unique=True, nullable=False)
    type = Column(String, nullable=False)
    livemode = Column(Boolean, nullable=True)
    payload = Column(JSON, nullable=False)
    received_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    booking_intent_id = Column(UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    processing_error = Column(JSON, nullable=True)

    # Relationships
    booking_intent = relationship("BookingIntent", back_populates="stripe_events")
