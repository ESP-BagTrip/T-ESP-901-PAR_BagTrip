"""Routes pour les trips."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.trips.schemas import (
    TripCreateRequest,
    TripDetailResponse,
    TripGroupedResponse,
    TripHomeResponse,
    TripListResponse,
    TripResponse,
    TripStatusUpdateRequest,
    TripUpdateRequest,
)
from src.config.database import get_db
from src.models.flight_order import FlightOrder
from src.models.hotel_booking import HotelBooking
from src.models.user import User
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
            cover_image_url=request.coverImageUrl,
        )
        return TripResponse.model_validate(trip)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "",
    response_model=TripListResponse,
    summary="List user trips",
    description="Get all trips for the authenticated user",
)
async def list_trips(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lister les trips de l'utilisateur."""
    try:
        trips = TripsService.get_trips_by_user(db, current_user.id)
        return TripListResponse(items=[TripResponse.model_validate(trip) for trip in trips])
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/grouped",
    response_model=TripGroupedResponse,
    summary="Get trips grouped by status",
    description="Get all trips grouped by status (active, planning, completed, archived)",
)
async def get_grouped_trips(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer les trips groupés par statut."""
    try:
        grouped = TripsService.get_grouped_trips(db, current_user.id)
        return TripGroupedResponse(
            active=[TripResponse.model_validate(t) for t in grouped["active"]],
            planning=[TripResponse.model_validate(t) for t in grouped["planning"]],
            completed=[TripResponse.model_validate(t) for t in grouped["completed"]],
            archived=[TripResponse.model_validate(t) for t in grouped["archived"]],
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer un trip avec agrégations."""
    try:
        trip = TripsService.get_trip_by_id(db, tripId, current_user.id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        flight_order = db.query(FlightOrder).filter(FlightOrder.trip_id == tripId).first()
        hotel_booking = db.query(HotelBooking).filter(HotelBooking.trip_id == tripId).first()

        flight_order_dict = None
        if flight_order:
            flight_order_dict = {
                "id": str(flight_order.id),
                "amadeusFlightOrderId": flight_order.amadeus_flight_order_id,
                "status": flight_order.status,
            }

        hotel_booking_dict = None
        if hotel_booking:
            hotel_booking_dict = {
                "id": str(hotel_booking.id),
                "amadeusBookingId": hotel_booking.amadeus_booking_id,
                "status": hotel_booking.status,
            }

        return TripDetailResponse(
            trip=TripResponse.model_validate(trip),
            flightOrder=flight_order_dict,
            hotelBooking=hotel_booking_dict,
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer les données de la page d'accueil d'un trip."""
    try:
        data = TripsService.get_trip_home(db, tripId, current_user.id)
        return TripHomeResponse(
            trip=TripResponse.model_validate(data["trip"]),
            stats=data["stats"],
            features=data["features"],
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mettre à jour un trip."""
    try:
        trip = TripsService.update_trip(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
            title=request.title,
            origin_iata=request.originIata,
            destination_iata=request.destinationIata,
            start_date=request.startDate,
            end_date=request.endDate,
            status=request.status,
            description=request.description,
            destination_name=request.destinationName,
            nb_travelers=request.nbTravelers,
            cover_image_url=request.coverImageUrl,
        )
        return TripResponse.model_validate(trip)
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mettre à jour le statut d'un trip."""
    try:
        trip = TripsService.update_trip_status(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
            new_status=request.status,
        )
        return TripResponse.model_validate(trip)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete trip",
    description="Delete a trip",
)
async def delete_trip(
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Supprimer un trip."""
    try:
        TripsService.delete_trip(db, tripId, current_user.id)
    except AppError as e:
        raise create_http_exception(e) from e
