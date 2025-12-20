"""Routes pour les travelers."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.travelers.schemas import (
    TravelerCreateRequest,
    TravelerListResponse,
    TravelerResponse,
    TravelerUpdateRequest,
)
from src.config.database import get_db
from src.models.user import User
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Créer un traveler selon PLAN.md."""
    try:
        traveler = TravelersService.create_traveler(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
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
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lister les travelers d'un trip selon PLAN.md."""
    try:
        travelers = TravelersService.get_travelers_by_trip(db, tripId, current_user.id)
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
    tripId: UUID = Path(..., description="Trip ID"),
    travelerId: UUID = Path(..., description="Traveler ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mettre à jour un traveler selon PLAN.md."""
    try:
        traveler = TravelersService.update_traveler(
            db=db,
            traveler_id=travelerId,
            trip_id=tripId,
            user_id=current_user.id,
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
    tripId: UUID = Path(..., description="Trip ID"),
    travelerId: UUID = Path(..., description="Traveler ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Supprimer un traveler selon PLAN.md."""
    try:
        TravelersService.delete_traveler(db, travelerId, tripId, current_user.id)
    except AppError as e:
        raise create_http_exception(e) from e
