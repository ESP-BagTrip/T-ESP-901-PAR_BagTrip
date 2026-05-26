"""Service aggregating everything the mobile Home screen needs in one call.

SMP327-021 — the Home screen used to fire ~5 separate requests at load
(current user + 3 paginated trip groups + active-trip activities + active-trip
weather). ``HomeService.get_home`` assembles all of it server-side so the
client makes a single round trip.

The active trip is the first ONGOING trip (the mobile bloc picks the earliest
by start date for its hero, but the screen consumes the whole ONGOING list, so
returning the first row here matches the contract the client derives from).
Trips are eager-loaded with their activities to avoid an N+1 when computing
completion and when pulling the active trip's activities.
"""

from datetime import date as _date
from datetime import time as _time
from typing import TYPE_CHECKING
from uuid import UUID

from sqlalchemy import literal_column
from sqlalchemy.orm import Query, Session, selectinload

from src.enums import TripStatus
from src.models.activity import Activity
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User

if TYPE_CHECKING:
    from src.api.auth.schemas import UserResponse

# Page-1 cap per group — matches the mobile bloc which loads `limit: 5` per
# status group at Home load.
HOME_GROUP_LIMIT = 5

# Sentinels for sorting nullable date/time keys (None pushed to the end).
_MIN_DATE = _date.min
_MIN_TIME = _time.min


class HomeService:
    """Aggregate Home screen data for the authenticated user."""

    @staticmethod
    def _grouped_trips(
        db: Session,
        user_id: UUID,
    ) -> dict[str, list[tuple[Trip, str]]]:
        """Fetch the user's trips (owned + shared) grouped + capped by status.

        Eager-loads ``activities`` so completion computation and the active
        trip's activity list don't trigger N+1 queries.
        """
        owned: Query = (
            db.query(Trip, literal_column("'OWNER'").label("role"))
            .options(selectinload(Trip.activities))
            .filter(Trip.user_id == user_id)
        )
        shared = (
            db.query(Trip, TripShare.role)
            .options(selectinload(Trip.activities))
            .join(TripShare, TripShare.trip_id == Trip.id)
            .filter(TripShare.user_id == user_id)
        )
        rows = owned.union_all(shared).order_by(Trip.created_at.desc()).all()

        grouped: dict[str, list[tuple[Trip, str]]] = {
            "ongoing": [],
            "planned": [],
            "completed": [],
        }
        for trip, role in rows:
            trip_status = trip.status or TripStatus.DRAFT
            if trip_status in (TripStatus.ONGOING, "active"):
                key = "ongoing"
            elif trip_status in (TripStatus.COMPLETED, "completed", "archived"):
                key = "completed"
            else:
                key = "planned"
            if len(grouped[key]) < HOME_GROUP_LIMIT:
                grouped[key].append((trip, role))
        return grouped

    @staticmethod
    async def _build_user_response(db: Session, user: User) -> "UserResponse":
        """Build the same enriched UserResponse that ``GET /v1/auth/me`` returns.

        Home must ship a user payload identical to ``/auth/me`` (the endpoint it
        replaces), so it reuses the same ProfileService completion check and
        PlanService quota lookup rather than a bare ``model_validate`` which
        would miss the computed ``is_profile_completed`` /
        ``ai_generations_remaining`` fields.
        """
        from src.api.auth.schemas import UserResponse
        from src.services.plan_service import PlanService
        from src.services.profile_service import ProfileService

        is_completed, _ = ProfileService.check_completion(db, user.id)
        plan_info = await PlanService.get_plan_info(db, user)
        return UserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            phone=user.phone,
            created_at=user.created_at,
            updated_at=user.updated_at,
            is_profile_completed=is_completed,
            email_verified=bool(user.email_verified),
            plan=user.plan or "FREE",
            ai_generations_remaining=plan_info["ai_generations_remaining"],
            plan_expires_at=user.plan_expires_at,
        )

    @staticmethod
    async def get_home(db: Session, user: User) -> dict:
        """Assemble the Home payload for ``user``.

        Returns a plain dict consumed by the route to build ``HomeResponse``::

            {
                "user": UserResponse,
                "ongoing": [(Trip, role), ...],
                "planned": [(Trip, role), ...],
                "completed": [(Trip, role), ...],
                "active_trip": Trip | None,
                "active_trip_activities": [Activity, ...],
                "active_trip_weather": dict | None,
            }
        """
        grouped = HomeService._grouped_trips(db, user.id)

        # Match the mobile bloc: earliest ongoing trip by start date (not list order).
        active_trip: Trip | None = None
        if grouped["ongoing"]:
            active_trip = min(
                (trip for trip, _ in grouped["ongoing"]),
                key=lambda t: (t.start_date is None, t.start_date or _MIN_DATE),
            )

        active_activities: list[Activity] = []
        active_weather: dict | None = None
        if active_trip is not None:
            # `activities` is already eager-loaded; sort in Python to mirror the
            # ActivityService ordering (date asc, start_time asc) without a
            # second query.
            active_activities = sorted(
                active_trip.activities,
                key=lambda a: (
                    a.date is None,
                    a.date or _MIN_DATE,
                    a.start_time is None,
                    a.start_time or _MIN_TIME,
                ),
            )
            from src.services.weather_service import WeatherService

            active_weather = await WeatherService.get_trip_weather(active_trip)

        user_response = await HomeService._build_user_response(db, user)

        return {
            "user": user_response,
            "ongoing": grouped["ongoing"],
            "planned": grouped["planned"],
            "completed": grouped["completed"],
            "active_trip": active_trip,
            "active_trip_activities": active_activities,
            "active_trip_weather": active_weather,
        }
