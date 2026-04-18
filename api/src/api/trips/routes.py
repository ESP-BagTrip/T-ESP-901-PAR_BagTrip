"""Routes pour les trips."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.common.pagination import PaginationParams
from src.api.trips.schemas import (
    TripCreateRequest,
    TripDetailResponse,
    TripGroupedResponse,
    TripHomeResponse,
    TripPaginatedResponse,
    TripResponse,
    TripStatusUpdateRequest,
    TripTrackingUpdateRequest,
    TripUpdateRequest,
    WeatherResponse,
)
from src.config.database import get_db
from src.enums import NotificationType, TripStatus
from src.models.flight_order import FlightOrder
from src.models.user import User
from src.services.notification_service import NotificationService
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Trips"])


def _enrich_with_completion(
    db: Session,
    trips: list,
    responses: list[TripResponse],
) -> None:
    """Set completionPercentage on TripResponse items using batch computation."""
    completions = TripsService.compute_completion_batch(db, trips)
    for resp, trip_obj in zip(responses, trips, strict=True):
        resp.completionPercentage = completions.get(trip_obj.id, 0)


@router.post(
    "",
    response_model=TripResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new trip",
    description="Create a new trip for the authenticated user",
)
async def create_trip(
    request: TripCreateRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Créer un nouveau trip."""
    try:
        # Auto-fetch cover image from Unsplash if not provided
        cover_url = request.coverImageUrl
        if not cover_url and request.destinationName:
            from src.integrations.unsplash import unsplash_client

            cover_url = await unsplash_client.fetch_cover_image(request.destinationName)
            if not cover_url:
                cover_url = unsplash_client.get_fallback_url(request.destinationName)

        trip = TripsService.create_trip(
            db=db,
            user_id=current_user.id,
            title=request.title,
            origin_iata=request.originIata,
            destination_iata=request.destinationIata,
            start_date=request.startDate,
            end_date=request.endDate,
            description=request.description,
            destination_name=request.destinationName,
            nb_travelers=request.nbTravelers,
            cover_image_url=cover_url,
            budget_total=request.budgetTotal,
            origin=request.origin,
            date_mode=request.dateMode,
        )
        resp = TripResponse.model_validate(trip)
        resp.role = "OWNER"
        _enrich_with_completion(db, [trip], [resp])
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "",
    response_model=TripPaginatedResponse,
    summary="List user trips (paginated)",
    description="Get paginated trips for the authenticated user (owned + shared)",
)
async def list_trips(
    pagination: Annotated[PaginationParams, Depends(PaginationParams)],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
    status: Annotated[
        str | None, Query(description="Filter by status: ongoing, planned, completed")
    ] = None,
):
    """Lister les trips de l'utilisateur (owned + shared) avec pagination."""
    try:
        rows, total, total_pages = TripsService.get_trips_by_user_paginated(
            db,
            current_user.id,
            page=pagination.page,
            limit=pagination.limit,
            status=status,
        )
        items = []
        trip_objects = []
        for trip, role in rows:
            resp = TripResponse.model_validate(trip)
            resp.role = role
            items.append(resp)
            trip_objects.append(trip)
        _enrich_with_completion(db, trip_objects, items)
        return TripPaginatedResponse(
            items=items,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/grouped",
    response_model=TripGroupedResponse,
    summary="Get trips grouped by status",
    description="Get all trips grouped by status (ongoing, planned, completed)",
)
async def get_grouped_trips(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[Session, Depends(get_db)],
):
    """Récupérer les trips groupés par statut."""
    try:
        grouped = TripsService.get_grouped_trips(db, current_user.id)
        result = {}
        for key, rows in grouped.items():
            items = []
            trip_objects = []
            for trip, role in rows:
                resp = TripResponse.model_validate(trip)
                resp.role = role
                items.append(resp)
                trip_objects.append(trip)
            _enrich_with_completion(db, trip_objects, items)
            result[key] = items
        return TripGroupedResponse(
            ongoing=result["ongoing"],
            planned=result["planned"],
            completed=result["completed"],
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}",
    response_model=TripDetailResponse,
    summary="Get trip details",
    description="Get detailed information about a specific trip with aggregations",
)
async def get_trip(
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Récupérer un trip avec agrégations."""
    try:
        trip = access.trip

        flight_order = db.query(FlightOrder).filter(FlightOrder.trip_id == trip.id).first()

        flight_order_dict = None
        if flight_order:
            flight_order_dict = {
                "id": str(flight_order.id),
                "amadeusFlightOrderId": flight_order.amadeus_flight_order_id,
                "status": flight_order.status,
            }

        trip_resp = TripResponse.model_validate(trip)
        trip_resp.role = access.role.value
        _enrich_with_completion(db, [trip], [trip_resp])

        return TripDetailResponse(
            trip=trip_resp,
            flightOrder=flight_order_dict,
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/home",
    response_model=TripHomeResponse,
    summary="Get trip home page data",
    description="Get trip details, stats, and feature tiles for the trip home page",
)
async def get_trip_home(
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Récupérer les données de la page d'accueil d'un trip."""
    try:
        data = TripsService.get_trip_home(db, access.trip)
        trip_obj = data["trip"]
        trip_resp = TripResponse.model_validate(trip_obj)
        trip_resp.role = access.role.value
        _enrich_with_completion(db, [trip_obj], [trip_resp])
        if access.role == TripRole.VIEWER:
            data["stats"]["totalExpenses"] = 0
        return TripHomeResponse(
            trip=trip_resp,
            stats=data["stats"],
            features=data["features"],
            sections=data["sections"],
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}",
    response_model=TripResponse,
    summary="Update trip",
    description="Update a trip's information",
)
async def update_trip(
    request: TripUpdateRequest,
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Mettre à jour un trip."""
    try:
        trip = TripsService.update_trip(
            db=db,
            trip=access.trip,
            title=request.title,
            origin_iata=request.originIata,
            destination_iata=request.destinationIata,
            start_date=request.startDate,
            end_date=request.endDate,
            description=request.description,
            destination_name=request.destinationName,
            nb_travelers=request.nbTravelers,
            cover_image_url=request.coverImageUrl,
            budget_total=request.budgetTotal,
            date_mode=request.dateMode,
        )
        resp = TripResponse.model_validate(trip)
        resp.role = "OWNER"
        _enrich_with_completion(db, [trip], [resp])
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/tracking",
    response_model=TripResponse,
    summary="Update trip tracking flags",
    description=(
        "Toggle whether BagTrip should track flights / accommodations for this trip. "
        "Users who book elsewhere set these to SKIPPED — companion mode alerts are "
        "suppressed for skipped domains and completion segments are treated as done."
    ),
)
async def update_trip_tracking(
    request: TripTrackingUpdateRequest,
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Mettre à jour les flags flights_tracking / accommodations_tracking."""
    try:
        trip = TripsService.update_tracking(
            db=db,
            trip=access.trip,
            flights_tracking=request.flightsTracking.value if request.flightsTracking else None,
            accommodations_tracking=(
                request.accommodationsTracking.value if request.accommodationsTracking else None
            ),
        )
        resp = TripResponse.model_validate(trip)
        resp.role = "OWNER"
        _enrich_with_completion(db, [trip], [resp])
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/status",
    response_model=TripResponse,
    summary="Update trip status",
    description="Update a trip's status with transition validation",
)
async def update_trip_status(
    request: TripStatusUpdateRequest,
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Mettre à jour le statut d'un trip."""
    try:
        old_status = access.trip.status
        trip = TripsService.update_trip_status(
            db=db,
            trip=access.trip,
            new_status=request.status,
        )

        # Send TRIP_ENDED notification on manual ONGOING→COMPLETED closure
        if old_status == TripStatus.ONGOING and request.status == TripStatus.COMPLETED:
            recipients = NotificationService._get_trip_recipients(db, trip)
            NotificationService.create_and_send_bulk(
                db=db,
                user_ids=recipients,
                trip_id=trip.id,
                notif_type=NotificationType.TRIP_ENDED,
                title="Voyage terminé !",
                body=f"Votre voyage « {trip.title or 'sans titre'} » est terminé. Partagez votre avis !",
                data={"screen": "feedback", "tripId": str(trip.id)},
            )

        resp = TripResponse.model_validate(trip)
        resp.role = "OWNER"
        _enrich_with_completion(db, [trip], [resp])
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/weather",
    response_model=WeatherResponse,
    summary="Get current weather for trip destination",
    description="Resolve trip destination coordinates and return weather data",
)
async def get_trip_weather(
    access: Annotated[TripAccess, Depends(get_trip_access)],
):
    """Récupérer la météo pour la destination du trip."""
    from datetime import date, timedelta

    from src.agent.tools import get_weather, resolve_iata_code

    trip = access.trip

    destination = trip.destination_name
    if not destination:
        raise create_http_exception(
            AppError("No destination set for this trip", status_code=404),
        )

    # Resolve coordinates via Amadeus location search
    location_data = await resolve_iata_code(destination)
    if "error" in location_data or "lat" not in location_data:
        raise create_http_exception(
            AppError(f"Could not resolve coordinates for '{destination}'", status_code=404),
        )

    lat = location_data["lat"]
    lon = location_data["lon"]

    # Date range: max(start_date, today) to min(end_date, today + 7 days)
    today = date.today()
    start = max(trip.start_date, today) if trip.start_date else today
    end = (
        min(trip.end_date, today + timedelta(days=7))
        if trip.end_date
        else today + timedelta(days=7)
    )
    if end < start:
        end = start

    weather = await get_weather(lat, lon, start.isoformat(), end.isoformat())

    return WeatherResponse(
        avg_temp_c=weather.get("avg_temp_c", 20),
        description=weather.get("description", "Unknown"),
        rain_probability=weather.get("rain_probability", 0),
        source=weather.get("source", "unknown"),
    )


@router.delete(
    "/{tripId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete trip",
    description="Delete a trip",
)
async def delete_trip(
    access: Annotated[TripAccess, Depends(get_trip_owner_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Supprimer un trip."""
    try:
        TripsService.delete_trip(db, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e
