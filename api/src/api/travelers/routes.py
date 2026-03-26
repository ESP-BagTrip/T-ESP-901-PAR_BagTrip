"""Routes pour les travelers."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.api.travelers.schemas import (
    TravelerCreateRequest,
    TravelerListResponse,
    TravelerResponse,
    TravelerUpdateRequest,
)
from src.config.database import get_db
from src.services.travelers_service import TravelersService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Travelers"])


@router.post(
    "/{tripId}/travelers",
    response_model=TravelerResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a traveler",
    description="Add a traveler to a trip",
)
async def create_traveler(
    request: TravelerCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer un traveler selon PLAN.md."""
    try:
        traveler = TravelersService.create_traveler(
            db=db,
            trip_id=access.trip.id,
            amadeus_traveler_ref=request.amadeusTravelerRef,
            traveler_type=request.travelerType,
            first_name=request.firstName,
            last_name=request.lastName,
            date_of_birth=request.dateOfBirth,
            gender=request.gender,
            documents=request.documents,
            contacts=request.contacts,
        )
        return TravelerResponse.model_validate(traveler)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/travelers",
    response_model=TravelerListResponse,
    summary="List travelers",
    description="Get all travelers for a trip",
)
async def list_travelers(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister les travelers d'un trip selon PLAN.md."""
    try:
        travelers = TravelersService.get_travelers_by_trip(db, access.trip.id)
        return TravelerListResponse(items=[TravelerResponse.model_validate(t) for t in travelers])
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/travelers/{travelerId}",
    response_model=TravelerResponse,
    summary="Update traveler",
    description="Update a traveler's information",
)
async def update_traveler(
    request: TravelerUpdateRequest,
    travelerId: UUID = Path(..., description="Traveler ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Mettre à jour un traveler selon PLAN.md."""
    try:
        traveler = TravelersService.update_traveler(
            db=db,
            traveler_id=travelerId,
            trip_id=access.trip.id,
            amadeus_traveler_ref=request.amadeusTravelerRef,
            traveler_type=request.travelerType,
            first_name=request.firstName,
            last_name=request.lastName,
            date_of_birth=request.dateOfBirth,
            gender=request.gender,
            documents=request.documents,
            contacts=request.contacts,
        )
        return TravelerResponse.model_validate(traveler)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/travelers/{travelerId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete traveler",
    description="Delete a traveler from a trip",
)
async def delete_traveler(
    travelerId: UUID = Path(..., description="Traveler ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprimer un traveler selon PLAN.md."""
    try:
        TravelersService.delete_traveler(db, travelerId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e
