"""Schémas Pydantic pour les travelers."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel


class TravelerCreateRequest(BagtripRequestModel):
    """Requête de création de traveler selon PLAN.md."""

    amadeusTravelerRef: str | None = None
    travelerType: str = Field(..., description="ADULT | CHILD | etc.")
    firstName: str
    lastName: str
    dateOfBirth: date | None = None
    gender: str | None = None
    documents: list[dict] | None = None
    contacts: dict | None = None


class TravelerUpdateRequest(BagtripRequestModel):
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
    amadeusTravelerRef: str | None = Field(None, alias="amadeus_traveler_ref")
    travelerType: str = Field(..., alias="traveler_type")
    firstName: str = Field(..., alias="first_name")
    lastName: str = Field(..., alias="last_name")
    dateOfBirth: date | None = Field(None, alias="date_of_birth")
    gender: str | None = None
    documents: list[dict] | None = None
    contacts: dict | None = None
    createdAt: datetime = Field(..., alias="created_at")
    updatedAt: datetime = Field(..., alias="updated_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class TravelerListResponse(BaseModel):
    """Réponse liste de travelers selon PLAN.md."""

    items: list[TravelerResponse]
