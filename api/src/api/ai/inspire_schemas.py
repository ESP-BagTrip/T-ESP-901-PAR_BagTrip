"""Schemas pour l'inspiration IA."""

from pydantic import BaseModel


class InspireRequest(BaseModel):
    travelTypes: str | None = None
    budgetRange: str | None = None
    durationDays: int | None = None
    companions: str | None = None
    season: str | None = None
    constraints: str | None = None
    startDate: str | None = None
    endDate: str | None = None
    nbTravelers: int | None = None


class SuggestedActivity(BaseModel):
    title: str
    description: str
    category: str = "OTHER"
    estimatedCost: float | None = None


class TripSuggestion(BaseModel):
    destination: str
    destinationCountry: str
    durationDays: int
    budgetEur: int
    description: str
    activities: list[SuggestedActivity] = []
    matchReason: str | None = None


class InspireResponse(BaseModel):
    suggestions: list[TripSuggestion]


class AcceptInspirationRequest(BaseModel):
    suggestion: TripSuggestion
    startDate: str | None = None
    endDate: str | None = None
