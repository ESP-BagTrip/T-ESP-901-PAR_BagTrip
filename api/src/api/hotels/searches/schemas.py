"""Schémas Pydantic pour les recherches d'hôtels."""

from datetime import date
from uuid import UUID

from pydantic import BaseModel, Field


class HotelSearchCreateRequest(BaseModel):
    """Requête de création de recherche d'hôtel selon PLAN.md."""

    cityCode: str | None = Field(None, min_length=3, max_length=3)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
    checkIn: date
    checkOut: date
    adults: int = Field(..., ge=1)
    roomQty: int = Field(..., ge=1)
    currency: str | None = Field(None, min_length=3, max_length=3)


class HotelOfferSummary(BaseModel):
    """Résumé d'une offre d'hôtel pour la réponse."""

    id: UUID
    hotelId: str | None
    offerId: str | None
    totalPrice: float | None
    currency: str | None


class HotelSearchResponse(BaseModel):
    """Réponse de création de recherche selon PLAN.md."""

    searchId: UUID
    offers: list[HotelOfferSummary]


class HotelOfferDetail(BaseModel):
    """Détail d'une offre d'hôtel."""

    id: UUID
    hotelId: str | None
    offerId: str | None
    chainCode: str | None
    roomType: str | None
    currency: str | None
    totalPrice: float | None
    offer: dict  # offer_json complet


class HotelSearchDetailResponse(BaseModel):
    """Réponse détaillée d'une recherche selon PLAN.md."""

    search: dict
    offers: list[HotelOfferDetail]
