"""Modèle BaggageItem SQLAlchemy."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base
from src.enums import BaggageCategory

if TYPE_CHECKING:
    from src.models.trip import Trip


class BaggageItem(Base):
    """Modèle BaggageItem pour les éléments de bagages d'un trip."""

    __tablename__ = "baggage_items"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String, nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, server_default="1", default=1)
    is_packed: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default="false", default=False
    )
    category: Mapped[str] = mapped_column(
        String, nullable=False, server_default="OTHER", default=BaggageCategory.OTHER
    )
    notes: Mapped[str | None] = mapped_column(String, nullable=True)
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
    trip: Mapped["Trip"] = relationship("Trip", back_populates="baggage_items")
