"""Routes pour les feedbacks."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, get_trip_access
from src.api.feedback.schemas import (
    FeedbackCreateRequest,
    FeedbackListResponse,
    FeedbackResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.feedback_service import FeedbackService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Feedback"])


@router.post(
    "/{tripId}/feedback",
    response_model=FeedbackResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create feedback",
    description="Submit feedback for a completed trip (owner and viewers)",
)
async def create_feedback(
    request: FeedbackCreateRequest,
    access: TripAccess = Depends(get_trip_access),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Créer un feedback pour un trip terminé."""
    try:
        feedback = FeedbackService.create_feedback(
            db=db,
            trip_id=access.trip.id,
            user_id=current_user.id,
            overall_rating=request.overallRating,
            highlights=request.highlights,
            lowlights=request.lowlights,
            would_recommend=request.wouldRecommend,
        )
        return FeedbackResponse.model_validate(feedback)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/feedback",
    response_model=FeedbackListResponse,
    summary="List feedbacks",
    description="Get all feedbacks for a trip",
)
async def list_feedbacks(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister les feedbacks d'un trip."""
    try:
        feedbacks = FeedbackService.get_feedbacks_by_trip(db, access.trip.id)
        return FeedbackListResponse(
            items=[FeedbackResponse.model_validate(f) for f in feedbacks]
        )
    except AppError as e:
        raise create_http_exception(e) from e
