from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.api.budget_items.schemas import (
    BudgetItemCreateRequest,
    BudgetItemListResponse,
    BudgetItemResponse,
    BudgetItemUpdateRequest,
    BudgetSummaryResponse,
)
from src.config.database import get_db
from src.services.budget_item_service import BudgetItemService
from src.services.notification_service import NotificationService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["BudgetItems"])


@router.post(
    "/{tripId}/budget-items",
    response_model=BudgetItemResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_budget_item(
    request: BudgetItemCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        item = BudgetItemService.create(
            db=db,
            trip=access.trip,
            label=request.label,
            amount=request.amount,
            category=request.category or "OTHER",
            date=request.date,
            is_planned=request.isPlanned if request.isPlanned is not None else True,
        )
        NotificationService.check_and_send_budget_alert(db, access.trip)
        return BudgetItemResponse.model_validate(item)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/budget-items", response_model=BudgetItemListResponse)
async def list_budget_items(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    try:
        if access.role == TripRole.VIEWER:
            return BudgetItemListResponse(items=[])
        items = BudgetItemService.get_by_trip(db, access.trip.id)
        return BudgetItemListResponse(
            items=[BudgetItemResponse.model_validate(i) for i in items]
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/budget-items/summary", response_model=BudgetSummaryResponse)
async def get_budget_summary(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    try:
        summary = BudgetItemService.get_budget_summary(db, access.trip)
        if access.role == TripRole.VIEWER:
            total_budget = summary["total_budget"]
            total_spent = summary["total_spent"]
            percent_consumed = (
                (total_spent / total_budget * 100) if total_budget > 0 else 0
            )
            return BudgetSummaryResponse(
                total_budget=total_budget,
                total_spent=0,
                remaining=0,
                by_category={},
                percent_consumed=percent_consumed,
            )
        return BudgetSummaryResponse(**summary)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/budget-items/{itemId}", response_model=BudgetItemResponse)
async def get_budget_item(
    itemId: UUID = Path(..., description="Budget item ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    try:
        if access.role == TripRole.VIEWER:
            raise AppError("FORBIDDEN", 403, "Viewers cannot access budget item details")
        item = BudgetItemService.get_by_id(db, itemId, access.trip.id)
        return BudgetItemResponse.model_validate(item)
    except AppError as e:
        raise create_http_exception(e) from e


@router.put("/{tripId}/budget-items/{itemId}", response_model=BudgetItemResponse)
async def update_budget_item(
    request: BudgetItemUpdateRequest,
    itemId: UUID = Path(..., description="Budget item ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        item = BudgetItemService.update(
            db=db,
            trip=access.trip,
            item_id=itemId,
            label=request.label,
            amount=request.amount,
            category=request.category,
            date=request.date,
            is_planned=request.isPlanned,
        )
        NotificationService.check_and_send_budget_alert(db, access.trip)
        return BudgetItemResponse.model_validate(item)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/budget-items/{itemId}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_budget_item(
    itemId: UUID = Path(..., description="Budget item ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        BudgetItemService.delete(db, access.trip, itemId)
        NotificationService.check_and_send_budget_alert(db, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e
