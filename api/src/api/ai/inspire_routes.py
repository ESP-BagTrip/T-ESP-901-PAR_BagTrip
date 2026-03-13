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
from src.config.database import get_db
from src.models.user import User
from src.services.inspire_ai_service import InspireAIService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/ai", tags=["AI Inspiration"])


@router.post("/inspire", response_model=InspireResponse)
async def inspire(
    request: InspireRequest,
    current_user: User = Depends(get_current_user),
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
        )
        suggestions = [
            TripSuggestion(**s)
            for s in result.get("suggestions", [])
        ]
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
        )
        return {
            "id": str(trip.id),
            "title": trip.title,
            "status": trip.status,
            "destinationName": trip.destination_name,
            "description": trip.description,
            "budgetTotal": trip.budget_total,
            "origin": trip.origin,
        }
    except AppError as e:
        raise create_http_exception(e) from e
