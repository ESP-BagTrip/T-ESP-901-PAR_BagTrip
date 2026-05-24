"""Route pour l'écran Home agrégé (SMP327-021).

``GET /v1/home`` renvoie en une seule réponse tout ce dont l'écran d'accueil
mobile a besoin (trips groupés + user + activités/météo du trip actif),
remplaçant les ~5 appels séparés qu'il faisait au load.
"""

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from src.api.activities.schemas import ActivityResponse
from src.api.auth.middleware import get_current_user
from src.api.home.schemas import HomeResponse
from src.api.trips.routes import _enrich_with_completion
from src.api.trips.schemas import TripResponse, WeatherResponse
from src.config.database import get_db
from src.models.user import User
from src.services.home_service import HomeService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/home", tags=["Home"])


def _build_trip_responses(
    db: Session,
    rows: list,
) -> list[TripResponse]:
    """Map (Trip, role) rows to enriched TripResponse items."""
    items: list[TripResponse] = []
    trip_objects = []
    for trip, role in rows:
        resp = TripResponse.model_validate(trip)
        resp.role = role
        items.append(resp)
        trip_objects.append(trip)
    _enrich_with_completion(db, trip_objects, items)
    return items


@router.get(
    "",
    response_model=HomeResponse,
    summary="Aggregated Home screen data",
    description=(
        "Single-request payload for the mobile Home screen: trips grouped by "
        "status (ongoing/planned/completed, page-1 capped), the current user, "
        "and the active trip's activities + destination weather."
    ),
)
async def get_home(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Assembler les données de l'écran d'accueil en une seule réponse."""
    try:
        data = await HomeService.get_home(db, current_user)

        ongoing = _build_trip_responses(db, data["ongoing"])
        planned = _build_trip_responses(db, data["planned"])
        completed = _build_trip_responses(db, data["completed"])

        activities = [ActivityResponse.model_validate(a) for a in data["active_trip_activities"]]

        weather = data["active_trip_weather"]
        weather_resp = WeatherResponse(**weather) if weather is not None else None

        return HomeResponse(
            ongoingTrips=ongoing,
            plannedTrips=planned,
            completedTrips=completed,
            user=data["user"],
            activeTripActivities=activities,
            activeTripWeather=weather_resp,
        )
    except AppError as e:
        raise create_http_exception(e) from e
