"""Schémas Pydantic pour les accommodations."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel


class AccommodationCreateRequest(BagtripRequestModel):
    """Requête de création d'hébergement."""

    name: str
    address: str | None = None
    checkIn: datetime | None = None
    checkOut: datetime | None = None
    pricePerNight: float | None = None
    currency: str | None = None
    bookingReference: str | None = None
    notes: str | None = None
    validationStatus: str | None = None


class AccommodationUpdateRequest(BagtripRequestModel):
    """Requête de mise à jour d'hébergement."""

    name: str | None = None
    address: str | None = None
    checkIn: datetime | None = None
    checkOut: datetime | None = None
    pricePerNight: float | None = None
    currency: str | None = None
    bookingReference: str | None = None
    notes: str | None = None
    validationStatus: str | None = None


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
