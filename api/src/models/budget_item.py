import uuid

from sqlalchemy import Boolean, Column, Date, DateTime, ForeignKey, Index, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class BudgetItem(Base):
    __tablename__ = "budget_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    label = Column(String, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)
    category = Column(String, nullable=False, default="OTHER")
    date = Column(Date, nullable=True)
    is_planned = Column(Boolean, nullable=False, default=True)
    source_type = Column(String, nullable=True)  # "accommodation" | "flight_order" | None
    source_id = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index("ix_budget_items_source", "source_type", "source_id"),
    )

    trip = relationship("Trip", back_populates="budget_items")
