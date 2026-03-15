"""Schemas pour les suggestions de bagages IA."""

from pydantic import BaseModel


class SuggestedBaggageItem(BaseModel):
    name: str
    quantity: int = 1
    category: str = "Autre"
    reason: str | None = None


class BaggageSuggestionsResponse(BaseModel):
    items: list[SuggestedBaggageItem]
