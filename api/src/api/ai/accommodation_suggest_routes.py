"""Routes pour les suggestions d'hébergements IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.accommodation_suggest_schemas import (
    AccommodationSuggestionsResponse,
    AccommodationSuggestRequest,
    SuggestedAccommodationItem,
)
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.models.user import User
from src.services.accommodation_ai_service import AccommodationAIService
from src.services.accommodations_service import AccommodationsService
from src.services.activity_service import ActivityService
from src.services.plan_service import PlanService
from src.services.profile_service import ProfileService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["AI Accommodation Suggestions"])


@router.post("/{tripId}/accommodations/suggest", response_model=AccommodationSuggestionsResponse)
async def suggest_accommodations(
    request: AccommodationSuggestRequest | None = None,
    access: TripAccess = Depends(get_trip_owner_access),
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Suggère des hébergements pour un trip via IA."""
    try:
        trip = access.trip
        destination = trip.destination_name or trip.destination_iata or "Unknown"
        start_date = str(trip.start_date) if trip.start_date else None
        end_date = str(trip.end_date) if trip.end_date else None

        profile = ProfileService.get_profile(db, current_user.id)
        existing = AccommodationsService.get_accommodations_by_trip(db, trip.id)
        existing_names = [a.name for a in existing]
        duration_days = (trip.end_date - trip.start_date).days if trip.start_date and trip.end_date else None

        # Récupérer les activités planifiées pour le contexte quartier
        activities = ActivityService.get_by_trip(db, trip.id)
        activity_locations = [
            f"{a.title} ({a.location})" if a.location else a.title
            for a in activities
        ]

        result = AccommodationAIService.suggest_accommodations(
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
            existing_accommodations=existing_names if existing_names else None,
            planned_activities=activity_locations if activity_locations else None,
        )

        accommodations = [
            SuggestedAccommodationItem(**a)
            for a in result.get("accommodations", [])
        ]
        PlanService.increment_ai_generation(db, current_user)
        return AccommodationSuggestionsResponse(accommodations=accommodations)
    except AppError as e:
        raise create_http_exception(e) from e
