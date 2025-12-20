"""Schémas Pydantic pour les travelers."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class TravelerCreateRequest(BaseModel):
    """Requête de création de traveler selon PLAN.md."""

    amadeusTravelerRef: str | None = None
    travelerType: str = Field(..., description="ADULT | CHILD | etc.")
    firstName: str
    lastName: str
    dateOfBirth: date | None = None
    gender: str | None = None
    documents: list[dict] | None = None
    contacts: dict | None = None


class TravelerUpdateRequest(BaseModel):
    """Requête de mise à jour de traveler."""

    amadeusTravelerRef: str | None = None
    travelerType: str | None = None
    firstName: str | None = None
    lastName: str | None = None
    dateOfBirth: date | None = None
    gender: str | None = None
    documents: list[dict] | None = None
    contacts: dict | None = None


class TravelerResponse(BaseModel):
    """Réponse traveler selon PLAN.md."""

    id: UUID
    amadeusTravelerRef: str | None
    travelerType: str
    firstName: str
    lastName: str
    dateOfBirth: date | None
    gender: str | None
    documents: list[dict] | None
    contacts: dict | None
    createdAt: datetime
    updatedAt: datetime

    class Config:
        from_attributes = True
        populate_by_name = True


class TravelerListResponse(BaseModel):
    """Réponse liste de travelers selon PLAN.md."""

    items: list[TravelerResponse]
