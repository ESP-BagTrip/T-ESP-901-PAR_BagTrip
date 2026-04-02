"""Routes pour les vols manuels."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.api.flights.manual.schemas import (
    ManualFlightCreateRequest,
    ManualFlightListResponse,
    ManualFlightResponse,
    ManualFlightUpdateRequest,
)
from src.config.database import get_db
from src.services.manual_flight_service import ManualFlightService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Manual Flights"])


@router.post(
    "/{tripId}/flights/manual",
    response_model=ManualFlightResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a manual flight",
    description="Add a manual flight to a trip",
)
async def create_manual_flight(
    request: ManualFlightCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer un vol manuel."""
    try:
        flight = ManualFlightService.create_manual_flight(
            db=db,
            trip=access.trip,
            flight_number=request.flightNumber,
            airline=request.airline,
            departure_airport=request.departureAirport,
            arrival_airport=request.arrivalAirport,
            departure_date=request.departureDate,
            arrival_date=request.arrivalDate,
            price=request.price,
            currency=request.currency,
            notes=request.notes,
            flight_type=request.flightType,
        )
        return ManualFlightResponse.model_validate(flight)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/flights/manual",
    response_model=ManualFlightListResponse,
    summary="List manual flights",
    description="Get all manual flights for a trip",
)
async def list_manual_flights(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister les vols manuels d'un trip."""
    try:
        flights = ManualFlightService.get_manual_flights_by_trip(db, access.trip.id)
        items = [ManualFlightResponse.model_validate(f) for f in flights]
        return ManualFlightListResponse(items=items)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/flights/manual/{flightId}",
    response_model=ManualFlightResponse,
    summary="Get manual flight",
    description="Get a manual flight by ID",
)
async def get_manual_flight(
    flightId: UUID = Path(..., description="Flight ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Récupérer un vol manuel."""
    try:
        flight = ManualFlightService.get_manual_flight_by_id(db, flightId, access.trip.id)
        if not flight:
            raise AppError("FLIGHT_NOT_FOUND", 404, "Manual flight not found")
        return ManualFlightResponse.model_validate(flight)
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/flights/manual/{flightId}",
    response_model=ManualFlightResponse,
    summary="Update manual flight",
    description="Update a manual flight's information",
)
async def update_manual_flight(
    request: ManualFlightUpdateRequest,
    flightId: UUID = Path(..., description="Flight ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Mettre à jour un vol manuel."""
    try:
        # Build kwargs only for fields that were explicitly set in the request
        update_data = request.model_dump(exclude_unset=True)
        kwargs = {}
        field_mapping = {
            "flightNumber": "flight_number",
            "airline": "airline",
            "departureAirport": "departure_airport",
            "arrivalAirport": "arrival_airport",
            "departureDate": "departure_date",
            "arrivalDate": "arrival_date",
            "price": "price",
            "currency": "currency",
            "notes": "notes",
            "flightType": "flight_type",
        }
        for camel, snake in field_mapping.items():
            if camel in update_data:
                kwargs[snake] = update_data[camel]

        flight = ManualFlightService.update_manual_flight(
            db=db,
            flight_id=flightId,
            trip=access.trip,
            **kwargs,
        )
        return ManualFlightResponse.model_validate(flight)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/flights/manual/{flightId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete manual flight",
    description="Delete a manual flight from a trip",
)
async def delete_manual_flight(
    flightId: UUID = Path(..., description="Flight ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprimer un vol manuel."""
    try:
        ManualFlightService.delete_manual_flight(db, flightId, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e
