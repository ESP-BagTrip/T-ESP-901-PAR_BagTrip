"""Schémas Pydantic pour les vols manuels."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ManualFlightCreateRequest(BaseModel):
    """Requête de création de vol manuel."""

    flightNumber: str = Field(..., alias="flight_number")
    airline: str | None = None
    departureAirport: str | None = Field(default=None, alias="departure_airport")
    arrivalAirport: str | None = Field(default=None, alias="arrival_airport")
    departureDate: datetime | None = Field(default=None, alias="departure_date")
    arrivalDate: datetime | None = Field(default=None, alias="arrival_date")
    price: float | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str = Field(default="MAIN", alias="flight_type")
    validationStatus: str | None = Field(default=None, alias="validation_status")

    model_config = ConfigDict(populate_by_name=True)


class ManualFlightUpdateRequest(BaseModel):
    """Requête de mise à jour partielle d'un vol manuel."""

    flightNumber: str | None = Field(default=None, alias="flight_number")
    airline: str | None = None
    departureAirport: str | None = Field(default=None, alias="departure_airport")
    arrivalAirport: str | None = Field(default=None, alias="arrival_airport")
    departureDate: datetime | None = Field(default=None, alias="departure_date")
    arrivalDate: datetime | None = Field(default=None, alias="arrival_date")
    price: float | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str | None = Field(default=None, alias="flight_type")
    validationStatus: str | None = Field(default=None, alias="validation_status")

    model_config = ConfigDict(populate_by_name=True)


class ManualFlightResponse(BaseModel):
    """Réponse vol manuel."""

    id: UUID
    tripId: UUID = Field(..., alias="trip_id")
    flightNumber: str = Field(..., alias="flight_number")
    airline: str | None = None
    departureAirport: str | None = Field(None, alias="departure_airport")
    arrivalAirport: str | None = Field(None, alias="arrival_airport")
    departureDate: datetime | None = Field(None, alias="departure_date")
    arrivalDate: datetime | None = Field(None, alias="arrival_date")
    price: float | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str = Field(..., alias="flight_type")
    validationStatus: str = Field(default="MANUAL", alias="validation_status")
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ManualFlightListResponse(BaseModel):
    """Réponse liste de vols manuels."""

    items: list[ManualFlightResponse]
