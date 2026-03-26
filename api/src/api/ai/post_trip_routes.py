"""Routes pour les suggestions post-voyage IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.post_trip_schemas import PostTripSuggestion, PostTripSuggestionResponse
from src.api.auth.plan_guard import require_ai_quota, require_premium
from src.config.database import get_db
from src.models.user import User
from src.services.plan_service import PlanService
from src.services.post_trip_ai_service import PostTripAIService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/ai", tags=["AI Post-Trip"])


@router.post("/post-trip-suggestion", response_model=PostTripSuggestionResponse)
async def suggest_post_trip(
    current_user: User = Depends(require_ai_quota),
    _premium: User = Depends(require_premium),
    db: Session = Depends(get_db),
):
    """Suggère un prochain voyage basé sur l'historique de feedbacks."""
    try:
        result = PostTripAIService.suggest_next_trip(db, current_user.id)
        suggestion = PostTripSuggestion(**result.get("suggestion", result))
        PlanService.increment_ai_generation(db, current_user)
        return PostTripSuggestionResponse(suggestion=suggestion)
    except AppError as e:
        raise create_http_exception(e) from e
