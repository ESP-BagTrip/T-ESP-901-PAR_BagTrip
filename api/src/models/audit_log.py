"""Modèle AuditLog SQLAlchemy."""

import uuid
from datetime import datetime
from uuid import UUID as _UUID

from sqlalchemy import DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from src.config.database import Base


class AuditLog(Base):
    """Trace each admin mutation for compliance and debugging."""

    __tablename__ = "audit_logs"

    id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id: Mapped[_UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    action: Mapped[str] = mapped_column(String(50), nullable=False)  # CREATE, UPDATE, DELETE, etc.
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False)  # USER, TRIP, etc.
    entity_id: Mapped[_UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    diff_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # { field: { old, new } }
    metadata_: Mapped[dict | None] = mapped_column(
        "metadata", JSON, nullable=True
    )  # IP, user agent, etc.
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        Index("idx_audit_logs_entity", "entity_type", "entity_id"),
        Index("idx_audit_logs_actor", "actor_id"),
        Index("idx_audit_logs_created", "created_at"),
    )
