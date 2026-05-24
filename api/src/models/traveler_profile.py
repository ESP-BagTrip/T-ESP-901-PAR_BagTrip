"""Modèle TravelerProfile SQLAlchemy."""

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class TravelerProfile(Base):
    """Profil voyageur avec préférences de personnalisation."""

    __tablename__ = "traveler_profiles"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False, index=True
    )
    travel_types: Mapped[list | None] = mapped_column(JSON, nullable=True)
    travel_style: Mapped[str | None] = mapped_column(String, nullable=True)
    budget: Mapped[str | None] = mapped_column(String, nullable=True)
    companions: Mapped[str | None] = mapped_column(String, nullable=True)
    medical_constraints: Mapped[str | None] = mapped_column(String, nullable=True)
    travel_frequency: Mapped[str | None] = mapped_column(String, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
