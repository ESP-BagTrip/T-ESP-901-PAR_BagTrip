"""Routes pour les baggage items."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_editor_access
from src.api.baggage.schemas import (
    BaggageItemCreateRequest,
    BaggageItemListResponse,
    BaggageItemResponse,
    BaggageItemUpdateRequest,
    BaggageSuggestionListResponse,
)
from src.config.database import get_db
from src.models.user import User
from src.services.baggage_items_service import BaggageItemsService
from src.services.plan_service import PlanService
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
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Créer un élément de bagage."""
    try:
        baggage_item = BaggageItemsService.create_baggage_item(
            db=db,
            trip=access.trip,
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
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
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
    baggageItemId: Annotated[UUID, Path(..., description="Baggage item ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Mettre à jour un élément de bagage."""
    try:
        baggage_item = BaggageItemsService.update_baggage_item(
            db=db,
            baggage_item_id=baggageItemId,
            trip=access.trip,
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
    baggageItemId: Annotated[UUID, Path(..., description="Baggage item ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Supprimer un élément de bagage."""
    try:
        BaggageItemsService.delete_baggage_item(db, baggageItemId, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{tripId}/baggage/suggest",
    response_model=BaggageSuggestionListResponse,
    summary="AI baggage suggestions",
    description="Get AI-powered baggage suggestions for a trip",
)
async def suggest_baggage_items(
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Suggestions IA de bagages pour un trip."""
    try:
        items = await BaggageItemsService.suggest_baggage_items(db, access.trip)
        PlanService.increment_ai_generation(db, current_user)
        return BaggageSuggestionListResponse(items=items)
    except AppError as e:
        raise create_http_exception(e) from e
