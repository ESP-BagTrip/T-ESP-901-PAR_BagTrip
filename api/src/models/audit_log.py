"""Modèle AuditLog SQLAlchemy."""

import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.sql import func

from src.config.database import Base


class AuditLog(Base):
    """Trace each admin mutation for compliance and debugging."""

    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    action = Column(String(50), nullable=False)  # CREATE, UPDATE, DELETE, BAN, etc.
    entity_type = Column(String(50), nullable=False)  # USER, TRIP, ACTIVITY, etc.
    entity_id = Column(UUID(as_uuid=True), nullable=False)
    diff_json = Column(JSON, nullable=True)  # { field: { old, new } }
    metadata_ = Column("metadata", JSON, nullable=True)  # IP, user agent, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    __table_args__ = (
        Index("idx_audit_logs_entity", "entity_type", "entity_id"),
        Index("idx_audit_logs_actor", "actor_id"),
        Index("idx_audit_logs_created", "created_at"),
    )
