"""Routes pour les baggage items."""

from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.api.baggage.schemas import (
    BaggageItemCreateRequest,
    BaggageItemListResponse,
    BaggageItemResponse,
    BaggageItemUpdateRequest,
)
from src.config.database import get_db
from src.services.baggage_items_service import BaggageItemsService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Baggage"])


@router.post(
    "/{tripId}/baggage",
    response_model=BaggageItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a baggage item",
    description="Add a baggage item to a trip",
)
async def create_baggage_item(
    request: BaggageItemCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer un élément de bagage."""
    try:
        baggage_item = BaggageItemsService.create_baggage_item(
            db=db,
            trip_id=access.trip.id,
            name=request.name,
            quantity=request.quantity,
            is_packed=request.isPacked,
            category=request.category,
            notes=request.notes,
        )
        return BaggageItemResponse.model_validate(baggage_item)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "/{tripId}/baggage",
    response_model=BaggageItemListResponse,
    summary="List baggage items",
    description="Get all baggage items for a trip",
)
async def list_baggage_items(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister les éléments de bagage d'un trip."""
    try:
        baggage_items = BaggageItemsService.get_baggage_items_by_trip(db, access.trip.id)
        return BaggageItemListResponse(
            items=[BaggageItemResponse.model_validate(b) for b in baggage_items]
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.patch(
    "/{tripId}/baggage/{baggageItemId}",
    response_model=BaggageItemResponse,
    summary="Update baggage item",
    description="Update a baggage item's information",
)
async def update_baggage_item(
    request: BaggageItemUpdateRequest,
    baggageItemId: UUID = Path(..., description="Baggage item ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Mettre à jour un élément de bagage."""
    try:
        baggage_item = BaggageItemsService.update_baggage_item(
            db=db,
            baggage_item_id=baggageItemId,
            trip_id=access.trip.id,
            name=request.name,
            quantity=request.quantity,
            is_packed=request.isPacked,
            category=request.category,
            notes=request.notes,
        )
        return BaggageItemResponse.model_validate(baggage_item)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/baggage/{baggageItemId}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete baggage item",
    description="Delete a baggage item from a trip",
)
async def delete_baggage_item(
    baggageItemId: UUID = Path(..., description="Baggage item ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Supprimer un élément de bagage."""
    try:
        BaggageItemsService.delete_baggage_item(db, baggageItemId, access.trip.id)
    except AppError as e:
        raise create_http_exception(e) from e
