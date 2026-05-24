"""Schémas Pydantic pour l'écran Home agrégé (SMP327-021)."""

from pydantic import BaseModel

from src.api.activities.schemas import ActivityResponse
from src.api.auth.schemas import UserResponse
from src.api.trips.schemas import TripResponse, WeatherResponse


class HomeResponse(BaseModel):
    """Aggregated payload for the mobile Home screen.

    Bundles the three status-grouped trip lists (capped to page-1), the
    current user, and — for the active trip (first ONGOING, ``None`` when the
    user has none) — its activities and resolved destination weather. Reuses
    the existing per-domain response schemas so the mobile contract stays
    identical to the individual endpoints it replaces.
    """

    ongoingTrips: list[TripResponse] = []
    plannedTrips: list[TripResponse] = []
    completedTrips: list[TripResponse] = []
    user: UserResponse
    activeTripActivities: list[ActivityResponse] = []
    activeTripWeather: WeatherResponse | None = None
