"""Schemas pour les suggestions d'hébergements IA."""

from pydantic import BaseModel


class AccommodationSuggestRequest(BaseModel):
    constraints: str | None = None


class SuggestedAccommodationItem(BaseModel):
    type: str = "OTHER"
    name: str
    neighborhood: str | None = None
    priceRange: str | None = None
    currency: str | None = None
    reason: str | None = None
    searchKeywords: str | None = None


class AccommodationSuggestionsResponse(BaseModel):
    accommodations: list[SuggestedAccommodationItem]
