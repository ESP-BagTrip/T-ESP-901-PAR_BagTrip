"""Schémas Pydantic pour les partages de trips."""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from src.api.common.base_schema import BagtripRequestModel


class ShareCreateRequest(BagtripRequestModel):
    """Requête d'invitation de partage par email."""

    email: EmailStr
    message: str | None = None
    role: Literal["VIEWER", "EDITOR"] = "VIEWER"


class ShareResponse(BaseModel):
    """Réponse partage de trip."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    userId: UUID = Field(alias="user_id")
    role: str
    invitedAt: datetime = Field(alias="invited_at")
    userEmail: str = Field(alias="user_email")
    userFullName: str | None = Field(None, alias="user_full_name")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ShareCreateResponse(BaseModel):
    """Réponse création de partage (actif ou en attente)."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    userId: UUID | None = Field(None, alias="user_id")
    role: str
    invitedAt: datetime = Field(alias="invited_at")
    userEmail: str = Field(alias="user_email")
    userFullName: str | None = Field(None, alias="user_full_name")
    status: str = "active"
    inviteToken: str | None = Field(None, alias="invite_token")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class PendingInviteResponse(BaseModel):
    """Réponse invitation en attente."""

    id: UUID
    tripId: UUID = Field(alias="trip_id")
    email: str
    role: str
    token: str
    createdAt: datetime = Field(alias="created_at")
    expiresAt: datetime = Field(alias="expires_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ShareListResponse(BaseModel):
    """Réponse liste de partages."""

    items: list[ShareResponse]
    pendingInvites: list[PendingInviteResponse] = []
