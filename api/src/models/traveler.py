"""Modèle TripTraveler SQLAlchemy."""

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import JSON, Date, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.trip import Trip


class TripTraveler(Base):
    """Modèle TripTraveler selon PLAN.md."""

    __tablename__ = "trip_travelers"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    amadeus_traveler_ref: Mapped[str | None] = mapped_column(String, nullable=True)
    traveler_type: Mapped[str] = mapped_column(String, nullable=False)  # ADULT | CHILD | etc.
    first_name: Mapped[str] = mapped_column(String, nullable=False)
    last_name: Mapped[str] = mapped_column(String, nullable=False)
    date_of_birth: Mapped[date | None] = mapped_column(Date, nullable=True)
    gender: Mapped[str | None] = mapped_column(String, nullable=True)
    documents: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    contacts: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    raw: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # Full Amadeus payload
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
    trip: Mapped["Trip"] = relationship("Trip", back_populates="travelers")
