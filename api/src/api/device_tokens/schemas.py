"""Schémas Pydantic pour les device tokens."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DeviceTokenRegisterRequest(BaseModel):
    """Request body pour enregistrer un token FCM."""

    fcmToken: str = Field(..., alias="fcmToken")
    platform: str | None = None

    model_config = ConfigDict(populate_by_name=True)


class DeviceTokenResponse(BaseModel):
    """Response pour un device token."""

    id: UUID
    fcmToken: str = Field(alias="fcm_token")
    platform: str | None = None
    createdAt: datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
