"""Routes pour les suggestions de bagages IA."""

from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.baggage_suggest_schemas import BaggageSuggestionsResponse, SuggestedBaggageItem
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.models.flight_order import FlightOrder
from src.models.manual_flight import ManualFlight
from src.models.user import User
from src.services.activity_service import ActivityService
from src.services.baggage_ai_service import BaggageAIService
from src.services.baggage_items_service import BaggageItemsService
from src.services.plan_service import PlanService
from src.services.profile_service import ProfileService
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

        # Load traveler profile
        profile = ProfileService.get_profile(db, current_user.id)

        # Load activities — filter VALIDATED and MANUAL
        activities = ActivityService.get_by_trip(db, trip.id)
        validated_activities = [
            a.title for a in activities if a.validation_status in ("VALIDATED", "MANUAL")
        ]

        # Load existing baggage
        existing_items = BaggageItemsService.get_baggage_items_by_trip(db, trip.id)
        existing_baggage = [item.name for item in existing_items]

        # Load flight info
        flight_parts: list[str] = []
        manual_flights = db.query(ManualFlight).filter(ManualFlight.trip_id == trip.id).all()
        for mf in manual_flights:
            info = f"{mf.flight_number}"
            if mf.notes:
                info += f" ({mf.notes})"
            flight_parts.append(info)

        flight_orders = db.query(FlightOrder).filter(FlightOrder.trip_id == trip.id).all()
        for fo in flight_orders:
            if fo.amadeus_create_order_response:
                flight_parts.append(str(fo.amadeus_create_order_response))

        flight_info = "; ".join(flight_parts) if flight_parts else None

        result = BaggageAIService.suggest_baggage(
            destination=destination,
            duration_days=duration_days,
            season=season,
            travel_types=", ".join(profile.travel_types) if profile and profile.travel_types else None,
            travel_style=profile.travel_style if profile else None,
            budget=profile.budget if profile else None,
            companions=profile.companions if profile else None,
            validated_activities=validated_activities if validated_activities else None,
            flight_info=flight_info,
            medical_constraints=profile.medical_constraints if profile else None,
            existing_baggage=existing_baggage if existing_baggage else None,
        )

        items = [
            SuggestedBaggageItem(**item)
            for item in result.get("items", [])
        ]
        PlanService.increment_ai_generation(db, current_user)
        return BaggageSuggestionsResponse(items=items)
    except AppError as e:
        raise create_http_exception(e) from e
