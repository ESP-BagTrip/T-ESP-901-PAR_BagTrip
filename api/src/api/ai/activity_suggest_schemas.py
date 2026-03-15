"""Schemas pour les suggestions d'activités IA."""

from pydantic import BaseModel


class ActivitySuggestRequest(BaseModel):
    constraints: str | None = None


class SuggestedActivityItem(BaseModel):
    title: str
    description: str
    category: str = "OTHER"
    estimatedCost: float | None = None
    location: str | None = None
    suggestedDay: int | None = None


class ActivitySuggestionsResponse(BaseModel):
    activities: list[SuggestedActivityItem]
