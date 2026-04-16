"""Modèle FlightOffer SQLAlchemy."""

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
    from src.models.flight_search import FlightSearch


class FlightOffer(Base):
    """Modèle FlightOffer selon PLAN.md."""

    __tablename__ = "flight_offers"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    flight_search_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("flight_searches.id"), nullable=False, index=True
    )
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    amadeus_offer_id: Mapped[str | None] = mapped_column(String, nullable=True)
    source: Mapped[str | None] = mapped_column(String, nullable=True)
    validating_airline_codes: Mapped[str | None] = mapped_column(String, nullable=True)
    last_ticketing_datetime: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    currency: Mapped[str | None] = mapped_column(String(3), nullable=True)
    grand_total: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    base_total: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    offer_json: Mapped[dict] = mapped_column(JSON, nullable=False)  # Full Amadeus offer
    priced_offer_json: Mapped[dict | None] = mapped_column(
        JSON, nullable=True
    )  # Priced offer if repriced
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    flight_search: Mapped["FlightSearch"] = relationship("FlightSearch", back_populates="offers")
    orders: Mapped[list["FlightOrder"]] = relationship("FlightOrder", back_populates="flight_offer")
