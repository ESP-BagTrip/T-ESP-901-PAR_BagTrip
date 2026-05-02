"""Modèle Trip SQLAlchemy."""

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base
from src.enums import DateMode, TrackingStatus, TripStatus

if TYPE_CHECKING:
    from src.models.accommodation import Accommodation
    from src.models.activity import Activity
    from src.models.baggage_item import BaggageItem
    from src.models.booking_intent import BookingIntent
    from src.models.budget_item import BudgetItem
    from src.models.feedback import Feedback
    from src.models.flight_search import FlightSearch
    from src.models.manual_flight import ManualFlight
    from src.models.traveler import TripTraveler
    from src.models.trip_share import TripShare


class Trip(Base):
    """Modèle Trip selon PLAN.md."""

    __tablename__ = "trips"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    title: Mapped[str | None] = mapped_column(String, nullable=True)
    origin_iata: Mapped[str | None] = mapped_column(String(3), nullable=True)
    destination_iata: Mapped[str | None] = mapped_column(String(3), nullable=True)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[str] = mapped_column(
        String, nullable=False, server_default="DRAFT", default=TripStatus.DRAFT
    )
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    # Topic 02 — `budget_total` was split into three explicit semantics
    # (cf. migration 0029). `budget_target` is the user's stated intent,
    # `budget_estimated` is the AI estimation accepted via /budget/estimate
    # /accept, and `budget_actual` is reserved for future materialisation
    # (currently computed at runtime by BudgetItemService.get_budget_summary).
    budget_target: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    budget_estimated: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    budget_actual: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    # Topic 04b — canonical currency the trip's aggregates are reported in.
    # All `BudgetItem.amount` values are converted to this code by
    # `BudgetItemService.get_budget_summary` before aggregation.
    currency: Mapped[str] = mapped_column(
        String(3), nullable=False, server_default="EUR", default="EUR"
    )
    origin: Mapped[str | None] = mapped_column(String, nullable=True, default="MANUAL")
    cover_image_url: Mapped[str | None] = mapped_column(String, nullable=True)
    destination_name: Mapped[str | None] = mapped_column(String, nullable=True)
    destination_timezone: Mapped[str | None] = mapped_column(String, nullable=True)
    nb_travelers: Mapped[int | None] = mapped_column(Integer, nullable=True, default=1)
    date_mode: Mapped[str] = mapped_column(
        String, nullable=False, server_default="EXACT", default=DateMode.EXACT
    )
    flights_tracking: Mapped[str] = mapped_column(
        String, nullable=False, server_default="TRACKED", default=TrackingStatus.TRACKED
    )
    accommodations_tracking: Mapped[str] = mapped_column(
        String, nullable=False, server_default="TRACKED", default=TrackingStatus.TRACKED
    )
    archived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
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
    travelers: Mapped[list["TripTraveler"]] = relationship(
        "TripTraveler", back_populates="trip", cascade="all, delete-orphan"
    )
    accommodations: Mapped[list["Accommodation"]] = relationship(
        "Accommodation", back_populates="trip", cascade="all, delete-orphan"
    )
    baggage_items: Mapped[list["BaggageItem"]] = relationship(
        "BaggageItem", back_populates="trip", cascade="all, delete-orphan"
    )
    flight_searches: Mapped[list["FlightSearch"]] = relationship(
        "FlightSearch", back_populates="trip", cascade="all, delete-orphan"
    )
    booking_intents: Mapped[list["BookingIntent"]] = relationship(
        "BookingIntent", back_populates="trip", cascade="all, delete-orphan"
    )
    shares: Mapped[list["TripShare"]] = relationship(
        "TripShare", back_populates="trip", cascade="all, delete-orphan"
    )
    activities: Mapped[list["Activity"]] = relationship(
        "Activity", back_populates="trip", cascade="all, delete-orphan"
    )
    budget_items: Mapped[list["BudgetItem"]] = relationship(
        "BudgetItem", back_populates="trip", cascade="all, delete-orphan"
    )
    feedbacks: Mapped[list["Feedback"]] = relationship(
        "Feedback", back_populates="trip", cascade="all, delete-orphan"
    )
    manual_flights: Mapped[list["ManualFlight"]] = relationship(
        "ManualFlight", back_populates="trip", cascade="all, delete-orphan"
    )
