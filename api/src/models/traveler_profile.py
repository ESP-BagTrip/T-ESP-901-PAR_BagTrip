"""Modèle TravelerProfile SQLAlchemy."""

import uuid

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.sql import func

from src.config.database import Base


class TravelerProfile(Base):
    """Profil voyageur avec préférences de personnalisation."""

    __tablename__ = "traveler_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(
        UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False, index=True
    )
    travel_types = Column(JSON, nullable=True)
    travel_style = Column(String, nullable=True)
    budget = Column(String, nullable=True)
    companions = Column(String, nullable=True)
    medical_constraints = Column(String, nullable=True)
    is_completed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
