"""Schemas pour les suggestions post-voyage IA."""

from pydantic import BaseModel


class PostTripActivity(BaseModel):
    title: str
    description: str
    category: str = "OTHER"
    estimatedCost: float | None = None


class PostTripSuggestion(BaseModel):
    destination: str
    destinationCountry: str
    durationDays: int
    budgetEur: int
    description: str
    highlightsMatch: list[str] = []
    activities: list[PostTripActivity] = []


class PostTripSuggestionResponse(BaseModel):
    suggestion: PostTripSuggestion
