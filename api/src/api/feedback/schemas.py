"""Schémas Pydantic pour les feedbacks."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from src.api.common.base_schema import BagtripRequestModel


class FeedbackCreateRequest(BagtripRequestModel):
    """Requête de création de feedback."""

    overallRating: int = Field(..., ge=1, le=5)
    highlights: str | None = None
    lowlights: str | None = None
    wouldRecommend: bool
    aiExperienceRating: int | None = Field(None, ge=1, le=5)


class FeedbackResponse(BaseModel):
    """Réponse feedback."""

    id: UUID
    tripId: UUID = Field(..., alias="trip_id")
    userId: UUID = Field(..., alias="user_id")
    overallRating: int = Field(..., alias="overall_rating")
    highlights: str | None = None
    lowlights: str | None = None
    wouldRecommend: bool = Field(..., alias="would_recommend")
    aiExperienceRating: int | None = Field(None, alias="ai_experience_rating")
    createdAt: datetime = Field(..., alias="created_at")

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


class FeedbackListResponse(BaseModel):
    """Réponse liste de feedbacks."""

    items: list[FeedbackResponse]
