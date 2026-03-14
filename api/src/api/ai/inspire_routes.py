"""Routes pour l'inspiration de voyages IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.inspire_schemas import (
    AcceptInspirationRequest,
    InspireRequest,
    InspireResponse,
    TripSuggestion,
)
from src.api.auth.middleware import get_current_user
from src.api.auth.plan_guard import require_ai_quota
from src.config.database import get_db
from src.models.user import User
from src.services.inspire_ai_service import InspireAIService
from src.services.plan_service import PlanService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/ai", tags=["AI Inspiration"])


@router.post("/inspire", response_model=InspireResponse)
async def inspire(
    request: InspireRequest,
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Génère des suggestions de voyages inspirantes via IA."""
    try:
        result = InspireAIService.generate_inspiration(
            travel_types=request.travelTypes,
            budget_range=request.budgetRange,
            duration_days=request.durationDays,
            companions=request.companions,
            season=request.season,
            constraints=request.constraints,
        )
        suggestions = [
            TripSuggestion(**s)
            for s in result.get("suggestions", [])
        ]
        PlanService.increment_ai_generation(db, current_user)
        return InspireResponse(suggestions=suggestions)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/inspire/accept")
async def accept_inspiration(
    request: AcceptInspirationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Crée un trip DRAFT à partir d'une suggestion IA acceptée."""
    try:
        trip = InspireAIService.create_trip_from_suggestion(
            db=db,
            user_id=current_user.id,
            suggestion=request.suggestion.model_dump(),
            start_date=request.startDate,
            end_date=request.endDate,
        )
        return {
            "id": str(trip.id),
            "title": trip.title,
            "status": trip.status,
            "destinationName": trip.destination_name,
            "description": trip.description,
            "budgetTotal": trip.budget_total,
            "origin": trip.origin,
            "startDate": str(trip.start_date) if trip.start_date else None,
            "endDate": str(trip.end_date) if trip.end_date else None,
        }
    except AppError as e:
        raise create_http_exception(e) from e
