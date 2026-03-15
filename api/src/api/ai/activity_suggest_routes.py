"""Routes pour les suggestions d'activités IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.activity_suggest_schemas import (
    ActivitySuggestionsResponse,
    ActivitySuggestRequest,
    SuggestedActivityItem,
)
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.models.user import User
from src.services.activity_ai_service import ActivityAIService
from src.services.activity_service import ActivityService
from src.services.plan_service import PlanService
from src.services.profile_service import ProfileService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["AI Activity Suggestions"])


@router.post("/{tripId}/activities/suggest", response_model=ActivitySuggestionsResponse)
async def suggest_activities(
    request: ActivitySuggestRequest | None = None,
    access: TripAccess = Depends(get_trip_owner_access),
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Suggère des activités pour un trip via IA."""
    try:
        trip = access.trip
        destination = trip.destination_name or trip.destination_iata or "Unknown"
        start_date = str(trip.start_date) if trip.start_date else None
        end_date = str(trip.end_date) if trip.end_date else None

        profile = ProfileService.get_profile(db, current_user.id)
        existing = ActivityService.get_by_trip(db, trip.id)
        existing_titles = [a.title for a in existing]
        duration_days = (trip.end_date - trip.start_date).days if trip.start_date and trip.end_date else None

        result = ActivityAIService.suggest_activities(
            destination=destination,
            start_date=start_date,
            end_date=end_date,
            description=trip.description,
            duration_days=duration_days,
            nb_travelers=None,
            travel_types=", ".join(profile.travel_types) if profile and profile.travel_types else None,
            travel_style=profile.travel_style if profile else None,
            budget=profile.budget if profile else None,
            companions=profile.companions if profile else None,
            constraints=request.constraints if request else None,
            existing_activities=existing_titles if existing_titles else None,
        )

        activities = [
            SuggestedActivityItem(**a)
            for a in result.get("activities", [])
        ]
        PlanService.increment_ai_generation(db, current_user)
        return ActivitySuggestionsResponse(activities=activities)
    except AppError as e:
        raise create_http_exception(e) from e
