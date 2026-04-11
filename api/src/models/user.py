"""Modèle User SQLAlchemy."""

import uuid

from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from src.config.database import Base


class User(Base):
    """Modèle User selon PLAN.md."""

    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    stripe_customer_id = Column(String, nullable=True, index=True)
    plan = Column(String(10), nullable=False, server_default="FREE")
    stripe_subscription_id = Column(String, nullable=True, index=True)
    plan_expires_at = Column(DateTime(timezone=True), nullable=True)
    ai_generations_count = Column(Integer, nullable=False, server_default="0")
    ai_generations_reset_at = Column(DateTime(timezone=True), nullable=True)
    password_reset_token = Column(String, nullable=True)
    password_reset_expires = Column(DateTime(timezone=True), nullable=True)
    banned_at = Column(DateTime(timezone=True), nullable=True)
    ban_reason = Column(String, nullable=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
