"""Schémas Pydantic pour les partages de trips."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class ShareCreateRequest(BaseModel):
    """Requête d'invitation de partage par email."""

    email: EmailStr
    message: str | None = None


class ShareResponse(BaseModel):
    """Réponse partage de trip."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    userId: UUID = Field(alias="user_id")
    role: str
    invitedAt: datetime = Field(alias="invited_at")
    userEmail: str = Field(alias="user_email")
    userFullName: str | None = Field(None, alias="user_full_name")

    class Config:
        from_attributes = True
        populate_by_name = True


class ShareListResponse(BaseModel):
    """Réponse liste de partages."""

    items: list[ShareResponse]
