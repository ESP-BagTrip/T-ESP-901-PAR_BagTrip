"""Schemas pour les suggestions d'activités IA."""

from pydantic import BaseModel


class SuggestedActivityItem(BaseModel):
    title: str
    description: str
    category: str = "OTHER"
    estimatedCost: float | None = None
    location: str | None = None


class ActivitySuggestionsResponse(BaseModel):
    activities: list[SuggestedActivityItem]
