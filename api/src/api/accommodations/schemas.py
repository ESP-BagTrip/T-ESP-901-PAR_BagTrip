"""Schémas Pydantic pour les accommodations."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class AccommodationCreateRequest(BaseModel):
    """Requête de création d'hébergement."""

    name: str
    address: str | None = None
    checkIn: datetime | None = None
    checkOut: datetime | None = None
    pricePerNight: Decimal | None = None
    currency: str | None = None
    bookingReference: str | None = None
    notes: str | None = None


class AccommodationUpdateRequest(BaseModel):
    """Requête de mise à jour d'hébergement."""

    name: str | None = None
    address: str | None = None
    checkIn: datetime | None = None
    checkOut: datetime | None = None
    pricePerNight: Decimal | None = None
    currency: str | None = None
    bookingReference: str | None = None
    notes: str | None = None


class AccommodationResponse(BaseModel):
    """Réponse hébergement."""

    id: UUID
    tripId: UUID = Field(..., alias="trip_id")
    name: str
    address: str | None = None
    checkIn: datetime | None = Field(None, alias="check_in")
    checkOut: datetime | None = Field(None, alias="check_out")
    pricePerNight: Decimal | None = Field(None, alias="price_per_night")
    currency: str | None = None
    bookingReference: str | None = Field(None, alias="booking_reference")
    notes: str | None = None
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class AccommodationListResponse(BaseModel):
    """Réponse liste d'hébergements."""

    items: list[AccommodationResponse]
