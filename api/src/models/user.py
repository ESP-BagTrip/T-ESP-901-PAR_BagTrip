"""Modèle User SQLAlchemy."""

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import DateTime, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class User(Base):
    """Modèle User selon PLAN.md."""

    __tablename__ = "users"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String, unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    full_name: Mapped[str | None] = mapped_column(String, nullable=True)
    phone: Mapped[str | None] = mapped_column(String, nullable=True)
    stripe_customer_id: Mapped[str | None] = mapped_column(String, nullable=True, index=True)
    plan: Mapped[str] = mapped_column(String(10), nullable=False, server_default="FREE")
    stripe_subscription_id: Mapped[str | None] = mapped_column(String, nullable=True, index=True)
    plan_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ai_generations_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    ai_generations_reset_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    password_reset_token: Mapped[str | None] = mapped_column(String, nullable=True)
    password_reset_expires: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    banned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ban_reason: Mapped[str | None] = mapped_column(String, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
