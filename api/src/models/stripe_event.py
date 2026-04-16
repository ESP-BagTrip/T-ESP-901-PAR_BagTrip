"""Modèle StripeEvent SQLAlchemy."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.booking_intent import BookingIntent


class StripeEvent(Base):
    """Modèle StripeEvent selon PLAN.md."""

    __tablename__ = "stripe_events"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    stripe_event_id: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    type: Mapped[str] = mapped_column(String, nullable=False)
    livemode: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    received_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    booking_intent_id: Mapped[_UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("booking_intents.id"), nullable=True
    )
    processed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    processing_error: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    # Relationships
    booking_intent: Mapped["BookingIntent | None"] = relationship(
        "BookingIntent", back_populates="stripe_events"
    )
