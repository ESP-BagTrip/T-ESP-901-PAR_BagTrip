"""Schémas Pydantic pour les device tokens."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DeviceTokenRegisterRequest(BaseModel):
    """Request body pour enregistrer un token FCM."""

    fcmToken: str = Field(..., alias="fcmToken")
    platform: str | None = None
    # Locale de l'app ("fr"/"en") — permet aux jobs de fond de localiser les push.
    locale: str | None = None

    model_config = ConfigDict(populate_by_name=True)


class DeviceTokenUnregisterRequest(BaseModel):
    """Request body pour désenregistrer un token FCM.

    Le token transite par le body (et non l'URL) pour ne pas atterrir
    dans les access logs serveur.
    """

    fcmToken: str = Field(..., alias="fcmToken")

    model_config = ConfigDict(populate_by_name=True)


class DeviceTokenResponse(BaseModel):
    """Response pour un device token."""

    id: UUID
    fcmToken: str = Field(alias="fcm_token")
    platform: str | None = None
    locale: str | None = None
    createdAt: datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
