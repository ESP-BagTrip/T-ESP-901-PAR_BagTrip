"""Routes pour les suggestions post-voyage IA."""

from typing import Annotated

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from src.api.ai.post_trip_schemas import (
    PostTripActivity,
    PostTripSuggestion,
    PostTripSuggestionResponse,
)
from src.api.auth.plan_guard import require_ai_quota, require_premium
from src.config.database import get_db
from src.models.user import User
from src.services.plan_service import PlanService
from src.services.post_trip_suggester import PostTripSuggester
from src.utils.errors import AppError, create_http_exception
from src.utils.locale import normalize_locale

router = APIRouter(prefix="/v1/ai", tags=["AI Post-Trip"])


@router.post("/post-trip-suggestion", response_model=PostTripSuggestionResponse)
async def suggest_post_trip(
    raw_request: Request,
    current_user: Annotated[User, Depends(require_ai_quota)],
    _premium: Annotated[User, Depends(require_premium)],
    db: Annotated[Session, Depends(get_db)],
):
    """Suggest the next trip from the user's feedback history.

    Uses the W3 RAG pipeline: BGE-M3 embedding of the user's recent
    feedback → cosine match against the curated destination catalogue
    → LLM narrative-only call that writes the description + activities
    for the locked destination.
    """
    try:
        locale = normalize_locale(raw_request.headers.get("accept-language"))
        result = await PostTripSuggester.suggest_next_trip(
            db=db, user_id=current_user.id, locale=locale
        )
        suggestion = PostTripSuggestion(
            destination=result.destination,
            destinationCountry=result.destinationCountry,
            durationDays=result.durationDays,
            budgetEur=result.budgetEur,
            description=result.description,
            highlightsMatch=result.highlightsMatch,
            activities=[PostTripActivity(**a) for a in result.activities],
        )
        PlanService.increment_ai_generation(db, current_user)
        return PostTripSuggestionResponse(suggestion=suggestion)
    except AppError as e:
        raise create_http_exception(e) from e
