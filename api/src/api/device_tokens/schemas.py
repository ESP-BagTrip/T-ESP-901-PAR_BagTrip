"""Schémas Pydantic pour les device tokens."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class DeviceTokenRegisterRequest(BaseModel):
    """Request body pour enregistrer un token FCM."""

    fcmToken: str = Field(..., alias="fcmToken")
    platform: str | None = None

    class Config:
        populate_by_name = True


class DeviceTokenResponse(BaseModel):
    """Response pour un device token."""

    id: UUID
    fcmToken: str = Field(alias="fcm_token")
    platform: str | None = None
    createdAt: datetime = Field(alias="created_at")

    class Config:
        from_attributes = True
        populate_by_name = True
