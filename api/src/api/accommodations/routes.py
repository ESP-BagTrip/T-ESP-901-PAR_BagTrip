"""Routes pour les accommodations."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.accommodations.schemas import (
    AccommodationCreateRequest,
    AccommodationListResponse,
    AccommodationResponse,
    AccommodationUpdateRequest,
)
from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.config.database import get_db
from src.services.accommodations_service import AccommodationsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Accommodations"])


@router.post(
    "/{tripId}/accommodations",
    response_model=AccommodationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an accommodation",
    description="Add an accommodation to a trip",
)
async def create_accommodation(
    request: AccommodationCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer un hébergement."""
    try:
        accommodation = AccommodationsService.create_accommodation(
            db=db,
            trip_id=access.trip.id,
            name=request.name,
            address=request.address,
            check_in=request.checkIn,
            check_out=request.checkOut,
            price=request.price,
            currency=request.currency,
            booking_reference=request.bookingReference,
            notes=request.notes,
        )
        return AccommodationResponse.model_validate(accommodation)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/accommodations",
    response_model=AccommodationListResponse,
    summary="List accommodations",
    description="Get all accommodations for a trip",
)
async def list_accommodations(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister les hébergements d'un trip."""
    try:
        accommodations = AccommodationsService.get_accommodations_by_trip(db, access.trip.id)
        return AccommodationListResponse(
            items=[AccommodationResponse.model_validate(a) for a in accommodations]
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/accommodations/{accommodationId}",
    response_model=AccommodationResponse,
    summary="Update accommodation",
    description="Update an accommodation's information",
)
async def update_accommodation(
    request: AccommodationUpdateRequest,
    accommodationId: UUID = Path(..., description="Accommodation ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Mettre à jour un hébergement."""
    try:
        price_explicitly_cleared = "price" in request.model_fields_set and request.price is None
        accommodation = AccommodationsService.update_accommodation(
            db=db,
            accommodation_id=accommodationId,
            trip_id=access.trip.id,
            name=request.name,
            address=request.address,
            check_in=request.checkIn,
            check_out=request.checkOut,
            price=request.price,
            currency=request.currency,
            booking_reference=request.bookingReference,
            notes=request.notes,
            price_explicitly_cleared=price_explicitly_cleared,
        )
        return AccommodationResponse.model_validate(accommodation)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/accommodations/{accommodationId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete accommodation",
    description="Delete an accommodation from a trip",
)
async def delete_accommodation(
    accommodationId: UUID = Path(..., description="Accommodation ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprimer un hébergement."""
    try:
        AccommodationsService.delete_accommodation(db, accommodationId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e
