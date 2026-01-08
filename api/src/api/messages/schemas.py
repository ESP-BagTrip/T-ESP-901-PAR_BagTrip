"""Schémas Pydantic pour les messages."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class MessageResponse(BaseModel):
    """Réponse message."""

    id: UUID
    conversationId: UUID = Field(alias="conversation_id")
    role: str  # "user", "assistant", "tool"
    content: str
    metadata: dict | None = Field(default=None, alias="message_metadata")
    createdAt: datetime = Field(alias="created_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class MessageListResponse(BaseModel):
    """Réponse liste de messages avec pagination."""

    items: list[MessageResponse]
    total: int
    limit: int
    offset: int
