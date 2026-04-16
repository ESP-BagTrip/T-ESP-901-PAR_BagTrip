"""Routes pour les accommodations."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.accommodations.schemas import (
    AccommodationCreateRequest,
    AccommodationListResponse,
    AccommodationResponse,
    AccommodationSuggestResponse,
    AccommodationUpdateRequest,
)
from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_editor_access
from src.config.database import get_db
from src.models.user import User
from src.services.accommodations_service import AccommodationsService
from src.services.plan_service import PlanService
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
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Créer un hébergement."""
    try:
        accommodation = AccommodationsService.create_accommodation(
            db=db,
            trip=access.trip,
            name=request.name,
            address=request.address,
            check_in=request.checkIn,
            check_out=request.checkOut,
            price_per_night=request.pricePerNight,
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
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Lister les hébergements d'un trip."""
    try:
        accommodations = AccommodationsService.get_accommodations_by_trip(db, access.trip.id)
        items = [AccommodationResponse.model_validate(a) for a in accommodations]
        if access.role == TripRole.VIEWER:
            for item in items:
                item.pricePerNight = None
                item.currency = None
                item.bookingReference = None
        return AccommodationListResponse(items=items)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{tripId}/accommodations/suggest",
    response_model=AccommodationSuggestResponse,
    summary="AI accommodation suggestions",
    description="Get AI-powered accommodation suggestions for a trip",
)
async def suggest_accommodations(
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Suggestions IA d'hébergements pour un trip."""
    try:
        suggestions = await AccommodationsService.suggest_accommodations(db, access.trip)
        PlanService.increment_ai_generation(db, current_user)
        return AccommodationSuggestResponse(accommodations=suggestions)
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
    accommodationId: Annotated[UUID, Path(..., description="Accommodation ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Mettre à jour un hébergement."""
    try:
        price_explicitly_cleared = (
            "pricePerNight" in request.model_fields_set and request.pricePerNight is None
        )
        accommodation = AccommodationsService.update_accommodation(
            db=db,
            accommodation_id=accommodationId,
            trip=access.trip,
            name=request.name,
            address=request.address,
            check_in=request.checkIn,
            check_out=request.checkOut,
            price_per_night=request.pricePerNight,
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
    accommodationId: Annotated[UUID, Path(..., description="Accommodation ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Supprimer un hébergement."""
    try:
        AccommodationsService.delete_accommodation(db, accommodationId, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e
