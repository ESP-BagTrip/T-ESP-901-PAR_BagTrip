"""Schémas Pydantic pour les trips."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class TripCreateRequest(BaseModel):
    """Requête de création de trip selon PLAN.md."""

    title: str | None = None
    originIata: str | None = None
    destinationIata: str | None = None
    startDate: date | None = None
    endDate: date | None = None


class TripUpdateRequest(BaseModel):
    """Requête de mise à jour de trip."""

    title: str | None = None
    originIata: str | None = None
    destinationIata: str | None = None
    startDate: date | None = None
    endDate: date | None = None
    status: str | None = None


class TripResponse(BaseModel):
    """Réponse trip selon PLAN.md."""

    id: UUID
    title: str | None = None
    originIata: str | None = Field(default=None, alias="origin_iata")
    destinationIata: str | None = Field(default=None, alias="destination_iata")
    startDate: date | None = Field(default=None, alias="start_date")
    endDate: date | None = Field(default=None, alias="end_date")
    status: str | None = None
    createdAt: datetime = Field(alias="created_at")
    updatedAt: datetime = Field(alias="updated_at")

    class Config:
        from_attributes = True
        populate_by_name = True


class TripListResponse(BaseModel):
    """Réponse liste de trips selon PLAN.md."""

    items: list[TripResponse]


class TripDetailResponse(BaseModel):
    """Réponse détaillée d'un trip avec agrégations selon PLAN.md."""

    trip: TripResponse
    flightOrder: dict | None = None
    hotelBooking: dict | None = None
