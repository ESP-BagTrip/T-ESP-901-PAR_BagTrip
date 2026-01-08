"""Modèle Context SQLAlchemy."""

import uuid

from sqlalchemy import Column, DateTime, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class Context(Base):
    """Modèle Context pour gérer le contexte (state + UI) d'une conversation."""

    __tablename__ = "contexts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    trip_id = Column(UUID(as_uuid=True), ForeignKey("trips.id"), nullable=False, index=True)
    conversation_id = Column(
        UUID(as_uuid=True), ForeignKey("conversations.id"), nullable=False, index=True
    )
    version = Column(Integer, nullable=False, default=1)  # Pour versioning et optimistic locking
    state = Column(JSON, nullable=False)  # LangChain state machine
    ui = Column(JSON, nullable=False)  # Widgets et actions UI
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    conversation = relationship("Conversation", back_populates="contexts")
    trip = relationship("Trip")
    user = relationship("User")
