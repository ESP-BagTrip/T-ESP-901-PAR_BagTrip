"""Routes pour l'estimation de budget IA."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.ai.budget_estimate_schemas import (
    BudgetEstimateAcceptRequest,
    BudgetEstimationItem,
    BudgetEstimationResponse,
)
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_owner_access
from src.config.database import get_db
from src.models.flight_order import FlightOrder
from src.models.manual_flight import ManualFlight
from src.models.user import User
from src.services.accommodations_service import AccommodationsService
from src.services.activity_service import ActivityService
from src.services.budget_ai_service import BudgetAiService
from src.services.plan_service import PlanService
from src.services.profile_service import ProfileService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["AI Budget Estimation"])


@router.post("/{tripId}/budget/estimate", response_model=BudgetEstimationResponse)
async def estimate_budget(
    access: TripAccess = Depends(get_trip_owner_access),
    current_user: User = Depends(require_ai_quota),
    db: Session = Depends(get_db),
):
    """Estime le budget d'un trip via IA."""
    try:
        trip = access.trip
        destination = trip.destination_name or trip.destination_iata or "Unknown"

        duration_days = 7
        if trip.start_date and trip.end_date:
            duration_days = max(1, (trip.end_date - trip.start_date).days)

        nb_travelers = trip.nb_travelers or 1

        # Load profile
        profile = ProfileService.get_profile(db, current_user.id)
        budget_profile = profile.budget if profile else None

        # Load accommodations
        accommodations = AccommodationsService.get_accommodations_by_trip(db, trip.id)
        known_accommodations = [
            {
                "name": a.name,
                "price_per_night": float(a.price_per_night) if a.price_per_night else None,
                "currency": a.currency,
            }
            for a in accommodations
        ] if accommodations else None

        # Load flights
        known_flights: list[dict] = []
        manual_flights = db.query(ManualFlight).filter(ManualFlight.trip_id == trip.id).all()
        for mf in manual_flights:
            known_flights.append({
                "flight_number": mf.flight_number,
                "price": float(mf.price) if mf.price else None,
                "currency": mf.currency,
            })
        flight_orders = db.query(FlightOrder).filter(FlightOrder.trip_id == trip.id).all()
        for fo in flight_orders:
            known_flights.append({
                "type": "amadeus_order",
                "data": fo.amadeus_create_order_response,
            })

        # Load activities
        activities = ActivityService.get_by_trip(db, trip.id)
        known_activities = [
            {
                "title": a.title,
                "estimated_cost": float(a.estimated_cost) if a.estimated_cost else None,
                "category": a.category,
            }
            for a in activities
        ] if activities else None

        result = BudgetAiService.estimate_budget(
            destination=destination,
            duration_days=duration_days,
            nb_travelers=nb_travelers,
            budget_profile=budget_profile,
            known_accommodations=known_accommodations,
            known_flights=known_flights if known_flights else None,
            known_activities=known_activities,
        )

        estimation = BudgetEstimationItem(**result.get("estimation", {}))
        PlanService.increment_ai_generation(db, current_user)
        return BudgetEstimationResponse(estimation=estimation)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post("/{tripId}/budget/estimate/accept")
async def accept_budget_estimate(
    body: BudgetEstimateAcceptRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Accepte une estimation de budget et met à jour le trip."""
    try:
        trip = access.trip
        trip.budget_total = body.budget_total
        db.commit()
        db.refresh(trip)
        return {"message": "Budget updated", "budget_total": float(trip.budget_total)}
    except AppError as e:
        raise create_http_exception(e) from e
