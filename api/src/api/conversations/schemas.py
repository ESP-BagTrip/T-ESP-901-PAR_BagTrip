"""Schémas Pydantic pour les conversations."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class ConversationCreateRequest(BaseModel):
    """Requête de création de conversation."""

    title: str | None = None


class ConversationResponse(BaseModel):
    """Réponse conversation."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    userId: UUID = Field(alias="user_id")
    title: str | None = None
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class ConversationListResponse(BaseModel):
    """Réponse liste de conversations."""

    items: list[ConversationResponse]


class ConversationDetailResponse(BaseModel):
    """Réponse détaillée d'une conversation."""

    conversation: ConversationResponse
