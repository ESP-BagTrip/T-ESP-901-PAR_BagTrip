import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import TYPE_CHECKING
from uuid import UUID as _UUID

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Index, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from src.config.database import Base

if TYPE_CHECKING:
    from src.models.trip import Trip


class BudgetItem(Base):
    __tablename__ = "budget_items"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True
    )
    label: Mapped[str] = mapped_column(String, nullable=False)
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    category: Mapped[str] = mapped_column(String, nullable=False, default="OTHER")
    date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_planned: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    source_type: Mapped[str | None] = mapped_column(
        String, nullable=True
    )  # "accommodation" | "flight_order" | None
    source_id: Mapped[_UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (Index("ix_budget_items_source", "source_type", "source_id"),)

    trip: Mapped["Trip"] = relationship("Trip", back_populates="budget_items")
