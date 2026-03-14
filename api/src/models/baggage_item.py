"""Modèle BaggageItem SQLAlchemy."""

import uuid

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base
from src.enums import BaggageCategory


class BaggageItem(Base):
    """Modèle BaggageItem pour les éléments de bagages d'un trip."""

    __tablename__ = "baggage_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    quantity = Column(Integer, nullable=False, server_default="1", default=1)
    is_packed = Column(Boolean, nullable=False, server_default="false", default=False)
    category = Column(String, nullable=False, server_default="OTHER", default=BaggageCategory.OTHER)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    trip = relationship("Trip", back_populates="baggage_items")
