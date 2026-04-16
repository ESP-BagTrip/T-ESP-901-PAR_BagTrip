"""Modèle ManualFlight SQLAlchemy."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.trip import Trip


class ManualFlight(Base):
    """Modèle ManualFlight pour les vols manuels d'un trip."""

    __tablename__ = "manual_flights"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    flight_number: Mapped[str] = mapped_column(String, nullable=False)
    airline: Mapped[str | None] = mapped_column(String, nullable=True)
    departure_airport: Mapped[str | None] = mapped_column(String, nullable=True)
    arrival_airport: Mapped[str | None] = mapped_column(String, nullable=True)
    departure_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    arrival_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    currency: Mapped[str | None] = mapped_column(String, nullable=True, default="EUR")
    notes: Mapped[str | None] = mapped_column(String, nullable=True)
    flight_type: Mapped[str] = mapped_column(String, nullable=False, default="MAIN")
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
    trip: Mapped["Trip"] = relationship("Trip", back_populates="manual_flights")
