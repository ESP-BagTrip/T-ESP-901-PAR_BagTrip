"""Schémas Pydantic pour le profil voyageur."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel


class ProfileCreateUpdateRequest(BagtripRequestModel):
    """Requête de création/mise à jour du profil voyageur."""

    travelTypes: list[str] | None = None
    travelStyle: str | None = None
    budget: str | None = None
    companions: str | None = None
    travelFrequency: str | None = None
    medicalConstraints: str | None = None


class ProfileResponse(BaseModel):
    """Réponse du profil voyageur."""

    id: UUID
    travel_types: list[str] | None = Field(None, alias="travelTypes")
    travel_style: str | None = Field(None, alias="travelStyle")
    budget: str | None = None
    companions: str | None = None
    travel_frequency: str | None = Field(None, alias="travelFrequency")
    medical_constraints: str | None = Field(None, alias="medicalConstraints")
    is_completed: bool = Field(False, alias="isCompleted")
    created_at: datetime = Field(..., alias="createdAt")
    updated_at: datetime = Field(..., alias="updatedAt")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class ProfileCompletionResponse(BaseModel):
    """Réponse de vérification de completion du profil."""

    is_completed: bool = Field(..., alias="isCompleted")
    missing_fields: list[str] = Field(..., alias="missingFields")

    model_config = ConfigDict(populate_by_name=True)
