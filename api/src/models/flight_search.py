"""Modèle FlightSearch SQLAlchemy."""

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import JSON, Boolean, Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.flight_offer import FlightOffer
    from src.models.trip import Trip


class FlightSearch(Base):
    """Modèle FlightSearch selon PLAN.md."""

    __tablename__ = "flight_searches"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    origin_iata: Mapped[str] = mapped_column(String(3), nullable=False)
    destination_iata: Mapped[str] = mapped_column(String(3), nullable=False)
    departure_date: Mapped[date] = mapped_column(Date, nullable=False)
    return_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    adults: Mapped[int] = mapped_column(Integer, nullable=False)
    children: Mapped[int | None] = mapped_column(Integer, nullable=True)
    infants: Mapped[int | None] = mapped_column(Integer, nullable=True)
    travel_class: Mapped[str | None] = mapped_column(String, nullable=True)
    non_stop: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    currency: Mapped[str | None] = mapped_column(String(3), nullable=True)
    amadeus_request: Mapped[dict] = mapped_column(JSON, nullable=False)
    amadeus_response: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    amadeus_response_received_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    trip: Mapped["Trip"] = relationship("Trip", back_populates="flight_searches")
    offers: Mapped[list["FlightOffer"]] = relationship(
        "FlightOffer", back_populates="flight_search", cascade="all, delete-orphan"
    )
