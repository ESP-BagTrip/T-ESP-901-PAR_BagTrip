"""Schémas Pydantic pour les notifications."""

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class NotificationResponse(BaseModel):
    """Response pour une notification."""

    id: UUID
    type: str
    title: str
    body: str
    data: Any | None = None
    isRead: bool = Field(alias="is_read")
    tripId: UUID | None = Field(None, alias="trip_id")
    sentAt: datetime | None = Field(None, alias="sent_at")
    createdAt: datetime = Field(alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class NotificationListResponse(BaseModel):
    """Response paginée pour les notifications."""

    items: list[NotificationResponse]
    total: int
    page: int
    limit: int
    totalPages: int = Field(alias="total_pages")
    unreadCount: int = Field(alias="unread_count")


class UnreadCountResponse(BaseModel):
    """Response pour le nombre de notifications non lues."""

    count: int


class NotificationPreferenceResponse(BaseModel):
    """Préférences de notifications de l'utilisateur."""

    pushEnabled: bool = Field(alias="push_enabled")
    flightReminders: bool = Field(alias="flight_reminders")
    activityReminders: bool = Field(alias="activity_reminders")
    tripUpdates: bool = Field(alias="trip_updates")
    budgetAlerts: bool = Field(alias="budget_alerts")
    social: bool

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class NotificationPreferenceUpdate(BaseModel):
    """Mise à jour partielle des préférences (tous les champs optionnels)."""

    pushEnabled: bool | None = Field(None, alias="push_enabled")
    flightReminders: bool | None = Field(None, alias="flight_reminders")
    activityReminders: bool | None = Field(None, alias="activity_reminders")
    tripUpdates: bool | None = Field(None, alias="trip_updates")
    budgetAlerts: bool | None = Field(None, alias="budget_alerts")
    social: bool | None = None

    model_config = ConfigDict(populate_by_name=True)
