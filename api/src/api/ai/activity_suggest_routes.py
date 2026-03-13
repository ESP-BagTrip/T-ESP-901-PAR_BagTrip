"""Routes pour les suggestions d'activités IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.activity_suggest_schemas import ActivitySuggestionsResponse, SuggestedActivityItem
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.services.activity_ai_service import ActivityAIService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["AI Activity Suggestions"])


@router.post("/{tripId}/activities/suggest", response_model=ActivitySuggestionsResponse)
async def suggest_activities(
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Suggère des activités pour un trip via IA."""
    try:
        trip = access.trip
        destination = trip.destination_name or trip.destination_iata or "Unknown"
        start_date = str(trip.start_date) if trip.start_date else None
        end_date = str(trip.end_date) if trip.end_date else None

        result = ActivityAIService.suggest_activities(
            destination=destination,
            start_date=start_date,
            end_date=end_date,
            description=trip.description,
        )

        activities = [
            SuggestedActivityItem(**a)
            for a in result.get("activities", [])
        ]
        return ActivitySuggestionsResponse(activities=activities)
    except AppError as e:
        raise create_http_exception(e) from e
