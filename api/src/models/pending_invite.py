"""Modèle PendingInvite SQLAlchemy — invitation en attente pour un utilisateur non inscrit."""

import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class PendingInvite(Base):
    """Invitation en attente pour un utilisateur non encore inscrit."""

    __tablename__ = "pending_invites"
    __table_args__ = (UniqueConstraint("trip_id", "email", name="uq_pending_invites_trip_email"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    email = Column(String, nullable=False, index=True)
    role = Column(String, nullable=False, default="VIEWER")
    token = Column(String, nullable=False, unique=True, index=True)
    message = Column(String, nullable=True)
    invited_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)

    trip = relationship("Trip")
    inviter = relationship("User", foreign_keys=[invited_by])
