"""Schémas Pydantic pour les baggage items."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.enums import BaggageCategory


class BaggageItemCreateRequest(BaseModel):
    """Requête de création d'élément de bagage."""

    name: str
    quantity: int | None = None
    isPacked: bool | None = None
    category: BaggageCategory | None = None
    notes: str | None = None


class BaggageItemUpdateRequest(BaseModel):
    """Requête de mise à jour d'élément de bagage."""

    name: str | None = None
    quantity: int | None = None
    isPacked: bool | None = None
    category: BaggageCategory | None = None
    notes: str | None = None


class BaggageItemResponse(BaseModel):
    """Réponse élément de bagage."""

    id: UUID
    tripId: UUID = Field(..., alias="trip_id")
    name: str
    quantity: int
    isPacked: bool = Field(alias="is_packed")
    category: str
    notes: str | None = None
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class BaggageItemListResponse(BaseModel):
    """Réponse liste d'éléments de bagage."""

    items: list[BaggageItemResponse]


class BaggageSuggestionItem(BaseModel):
    """Un élément de suggestion de bagage IA."""

    name: str
    quantity: int = 1
    category: str = "OTHER"
    reason: str | None = None


class BaggageSuggestionListResponse(BaseModel):
    """Réponse liste de suggestions de bagage IA."""

    items: list[BaggageSuggestionItem]
