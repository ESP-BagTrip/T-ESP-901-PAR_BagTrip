"""Modèle Message SQLAlchemy."""

import uuid

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from src.config.database import Base


class Message(Base):
    """Modèle Message pour persister les messages d'une conversation."""

    __tablename__ = "messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(
        UUID(as_uuid=True), ForeignKey("conversations.id"), nullable=False, index=True
    )
    role = Column(String, nullable=False)  # user | assistant | tool
    content = Column(Text, nullable=False)
    message_metadata = Column(JSON, nullable=True)  # Pour tool calls, offer_ids, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    conversation = relationship("Conversation", back_populates="messages")

    # Constraint to validate role
    __table_args__ = (
        CheckConstraint("role IN ('user', 'assistant', 'tool')", name="check_message_role"),
    )
