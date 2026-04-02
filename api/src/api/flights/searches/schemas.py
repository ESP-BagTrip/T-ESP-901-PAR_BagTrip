"""Schémas Pydantic pour les recherches de vols."""

from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class FlightSearchCreateRequest(BaseModel):
    """Requête de création de recherche de vol selon PLAN.md."""

    originIata: str = Field(..., min_length=3, max_length=3)
    destinationIata: str = Field(..., min_length=3, max_length=3)
    departureDate: date
    returnDate: date | None = None
    adults: int = Field(..., ge=1, le=9)
    children: int | None = Field(None, ge=0, le=9)
    infants: int | None = Field(None, ge=0, le=9)
    travelClass: str | None = None
    currency: str | None = Field(None, min_length=3, max_length=3)
    nonStop: bool | None = None


class FlightOfferSummary(BaseModel):
    """Résumé d'une offre de vol pour la réponse."""

    id: UUID
    grandTotal: float | None
    currency: str | None
    summary: dict | None = None  # Informations sur les stops, etc.


class FlightSearchResponse(BaseModel):
    """Réponse de création de recherche selon PLAN.md."""

    searchId: UUID
    offers: list[FlightOfferSummary]
    amadeusData: list | None = None
    dictionaries: dict | None = None


class FlightOfferDetail(BaseModel):
    """Détail d'une offre de vol."""

    id: UUID
    amadeusOfferId: str | None
    grandTotal: float | None
    baseTotal: float | None
    currency: str | None
    offer: dict  # offer_json complet


class FlightSearchDetailResponse(BaseModel):
    """Réponse détaillée d'une recherche selon PLAN.md."""

    search: dict
    offers: list[FlightOfferDetail]


class FlightSegmentRequest(BaseModel):
    """Un segment de recherche multi-destination."""

    originIata: str = Field(..., min_length=3, max_length=3)
    destinationIata: str = Field(..., min_length=3, max_length=3)
    departureDate: date


class MultiDestSearchCreateRequest(BaseModel):
    """Requête de recherche multi-destination."""

    segments: list[FlightSegmentRequest] = Field(..., min_length=1)
    adults: int = Field(..., ge=1, le=9)
    children: int | None = Field(None, ge=0, le=9)
    infants: int | None = Field(None, ge=0, le=9)
    travelClass: str | None = None
    currency: str | None = Field(None, min_length=3, max_length=3)
    nonStop: bool | None = None


class MultiDestSearchResponse(BaseModel):
    """Réponse de recherche multi-destination (un résultat par segment)."""

    segments: list[FlightSearchResponse]
