"""Schémas Pydantic pour le profil voyageur."""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel

# Allowed preference values — must match the personalization step contents
# shipped by the Flutter client (bagtrip/lib/personalization/widgets/*).
# A client can only ever send one of these; anything else is a 422 so we never
# persist garbage that downstream consumers (LLM agent, profile completion)
# would then have to guess about.
TravelStyle = Literal["planned", "flexible", "spontaneous"]
Budget = Literal["economical", "moderate", "comfort", "luxury"]
Companions = Literal["solo", "couple", "family", "friends"]
TravelFrequency = Literal["1-2", "3-5", "6+"]


class ProfileCreateUpdateRequest(BagtripRequestModel):
    """Requête de création/mise à jour du profil voyageur.

    The constrained fields stay nullable (a partial update may omit them) but
    a non-null value is validated against the closed set the client ships.
    """

    travelTypes: list[str] | None = None
    travelStyle: TravelStyle | None = None
    budget: Budget | None = None
    companions: Companions | None = None
    travelFrequency: TravelFrequency | None = None
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
