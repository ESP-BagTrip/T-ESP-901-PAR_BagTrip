"""Schémas Pydantic pour les accommodations."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AccommodationCreateRequest(BaseModel):
    """Requête de création d'hébergement."""

    name: str
    address: str | None = None
    checkIn: datetime | None = Field(default=None, alias="check_in")
    checkOut: datetime | None = Field(default=None, alias="check_out")
    pricePerNight: float | None = Field(default=None, alias="price_per_night")
    currency: str | None = None
    bookingReference: str | None = Field(default=None, alias="booking_reference")
    notes: str | None = None
    validationStatus: str | None = Field(default=None, alias="validation_status")

    model_config = ConfigDict(populate_by_name=True)


class AccommodationUpdateRequest(BaseModel):
    """Requête de mise à jour d'hébergement."""

    name: str | None = None
    address: str | None = None
    checkIn: datetime | None = Field(default=None, alias="check_in")
    checkOut: datetime | None = Field(default=None, alias="check_out")
    pricePerNight: float | None = Field(default=None, alias="price_per_night")
    currency: str | None = None
    bookingReference: str | None = Field(default=None, alias="booking_reference")
    notes: str | None = None
    validationStatus: str | None = Field(default=None, alias="validation_status")

    model_config = ConfigDict(populate_by_name=True)


class AccommodationResponse(BaseModel):
    """Réponse hébergement."""

    id: UUID
    tripId: UUID = Field(..., alias="trip_id")
    name: str
    address: str | None = None
    checkIn: datetime | None = Field(None, alias="check_in")
    checkOut: datetime | None = Field(None, alias="check_out")
    pricePerNight: float | None = Field(None, alias="price_per_night")
    currency: str | None = None
    bookingReference: str | None = Field(None, alias="booking_reference")
    notes: str | None = None
    validationStatus: str = Field(default="MANUAL", alias="validation_status")
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class AccommodationListResponse(BaseModel):
    """Réponse liste d'hébergements."""

    items: list[AccommodationResponse]


class AccommodationSuggestResponse(BaseModel):
    """Réponse suggestions IA d'hébergements."""

    accommodations: list[dict]
