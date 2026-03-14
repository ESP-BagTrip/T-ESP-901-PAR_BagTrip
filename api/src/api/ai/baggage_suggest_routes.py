"""Routes pour les suggestions de bagages IA."""

from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.baggage_suggest_schemas import BaggageSuggestionsResponse, SuggestedBaggageItem
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.models.user import User
from src.services.baggage_ai_service import BaggageAIService
from src.services.plan_service import PlanService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["AI Baggage Suggestions"])


def _guess_season(trip_date: date | None) -> str | None:
    """Devine la saison à partir de la date de début du trip."""
    if not trip_date:
        return None
    month = trip_date.month
    if month in (3, 4, 5):
        return "printemps"
    if month in (6, 7, 8):
        return "été"
    if month in (9, 10, 11):
        return "automne"
    return "hiver"


@router.post("/{tripId}/baggage/suggest", response_model=BaggageSuggestionsResponse)
async def suggest_baggage(
    access: TripAccess = Depends(get_trip_owner_access),
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Suggère des éléments de bagages pour un trip via IA."""
    try:
        trip = access.trip
        destination = trip.destination_name or trip.destination_iata or "Unknown"

        duration_days = 7
        if trip.start_date and trip.end_date:
            duration_days = max(1, (trip.end_date - trip.start_date).days)

        season = _guess_season(trip.start_date)

        result = BaggageAIService.suggest_baggage(
            destination=destination,
            duration_days=duration_days,
            season=season,
        )

        items = [
            SuggestedBaggageItem(**item)
            for item in result.get("items", [])
        ]
        PlanService.increment_ai_generation(db, current_user)
        return BaggageSuggestionsResponse(items=items)
    except AppError as e:
        raise create_http_exception(e) from e
