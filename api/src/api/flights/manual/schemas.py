"""Schémas Pydantic pour les vols manuels."""

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


class ManualFlightCreateRequest(BaseModel):
    """Requête de création de vol manuel."""

    flightNumber: str
    airline: str | None = None
    departureAirport: str | None = None
    arrivalAirport: str | None = None
    departureDate: datetime | None = None
    arrivalDate: datetime | None = None
    price: Decimal | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str = "MAIN"


class ManualFlightUpdateRequest(BaseModel):
    """Requête de mise à jour partielle d'un vol manuel."""

    flightNumber: str | None = None
    airline: str | None = None
    departureAirport: str | None = None
    arrivalAirport: str | None = None
    departureDate: datetime | None = None
    arrivalDate: datetime | None = None
    price: Decimal | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str | None = None


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
    price: Decimal | None = None
    currency: str | None = None
    notes: str | None = None
    flightType: str = Field(..., alias="flight_type")
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class ManualFlightListResponse(BaseModel):
    """Réponse liste de vols manuels."""

    items: list[ManualFlightResponse]
