"""Routes pour les trips."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.trips.schemas import (
    TripCreateRequest,
    TripDetailResponse,
    TripGroupedResponse,
    TripHomeResponse,
    TripListResponse,
    TripPaginatedResponse,
    TripResponse,
    TripStatusUpdateRequest,
    TripUpdateRequest,
)
from src.config.database import get_db
from src.enums import NotificationType, TripStatus
from src.models.flight_order import FlightOrder
from src.models.user import User
from src.services.notification_service import NotificationService
from src.services.trips_service import TripsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Trips"])


@router.post(
    "",
    response_model=TripResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new trip",
    description="Create a new trip for the authenticated user",
)
async def create_trip(
    request: TripCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
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
    page: int = Query(default=1, ge=1, description="Page number"),
    limit: int = Query(default=20, ge=1, le=100, description="Items per page"),
    status: str | None = Query(default=None, description="Filter by status: ongoing, planned, completed"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lister les trips de l'utilisateur (owned + shared) avec pagination."""
    try:
        rows, total, total_pages = TripsService.get_trips_by_user_paginated(
            db, current_user.id, page=page, limit=limit, status=status,
        )
        items = []
        for trip, role in rows:
            resp = TripResponse.model_validate(trip)
            resp.role = role
            items.append(resp)
        return TripPaginatedResponse(
            items=items, total=total, page=page, limit=limit, total_pages=total_pages,
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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer les trips groupés par statut."""
    try:
        grouped = TripsService.get_grouped_trips(db, current_user.id)
        result = {}
        for key, rows in grouped.items():
            items = []
            for trip, role in rows:
                resp = TripResponse.model_validate(trip)
                resp.role = role
                items.append(resp)
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
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
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
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupérer les données de la page d'accueil d'un trip."""
    try:
        data = TripsService.get_trip_home(db, access.trip)
        trip_resp = TripResponse.model_validate(data["trip"])
        trip_resp.role = access.role.value
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
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
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
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
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
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete trip",
    description="Delete a trip",
)
async def delete_trip(
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprimer un trip."""
    try:
        TripsService.delete_trip(db, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e
