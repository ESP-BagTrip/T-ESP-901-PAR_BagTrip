from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Path, status
from sqlalchemy.orm import Session

from src.api.auth.plan_guard import require_ai_quota
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_editor_access
from src.api.budget_items.schemas import (
    AcceptEstimateRequest,
    BudgetEstimateResponse,
    BudgetItemCreateRequest,
    BudgetItemListResponse,
    BudgetItemResponse,
    BudgetItemUpdateRequest,
    BudgetSummaryResponse,
)
from src.config.database import get_db
from src.models.user import User
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
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
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
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        if access.role == TripRole.VIEWER:
            return BudgetItemListResponse(items=[])
        items = BudgetItemService.get_by_trip(db, access.trip.id)
        return BudgetItemListResponse(items=[BudgetItemResponse.model_validate(i) for i in items])
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/budget-items/summary", response_model=BudgetSummaryResponse)
async def get_budget_summary(
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        summary = BudgetItemService.get_budget_summary(db, access.trip)
        if access.role == TripRole.VIEWER:
            total_budget = summary["total_budget"]
            total_spent = summary["total_spent"]
            percent_consumed = (total_spent / total_budget * 100) if total_budget > 0 else 0
            # Topic 06 (preview) — viewer sees the budget target shape but
            # never the spent / remaining figures. Estimated / actual stay
            # masked too so the viewer cannot reverse-derive them.
            return BudgetSummaryResponse(
                total_budget=total_budget,
                budget_target=total_budget,
                budget_estimated=None,
                budget_actual=0,
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
    itemId: Annotated[UUID, Path(..., description="Budget item ID")],
    access: Annotated[TripAccess, Depends(get_trip_access)],
    db: Annotated[Session, Depends(get_db)],
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
    itemId: Annotated[UUID, Path(..., description="Budget item ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
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
    itemId: Annotated[UUID, Path(..., description="Budget item ID")],
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    try:
        BudgetItemService.delete(db, access.trip, itemId)
        NotificationService.check_and_send_budget_alert(db, access.trip)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{tripId}/budget/estimate",
    response_model=BudgetEstimateResponse,
    summary="AI budget estimation",
    description="Get an AI-powered budget estimation for a trip",
)
async def estimate_budget(
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    current_user: Annotated[User, Depends(require_ai_quota)],
    db: Annotated[Session, Depends(get_db)],
):
    """Estimate budget using AI based on trip data."""
    from src.agent.nodes.budget import budget_node
    from src.services.plan_service import PlanService

    try:
        trip = access.trip

        # Build state from existing trip data
        state = {}
        if trip.destination_name:
            state["selected_destination"] = {
                "city": trip.destination_name,
                "iata": trip.destination_iata or "",
                "country": "",
            }
        if trip.origin_iata:
            state["origin_city"] = trip.origin_iata
        if trip.start_date:
            state["departure_date"] = str(trip.start_date)
        if trip.end_date:
            state["return_date"] = str(trip.end_date)
        if trip.start_date and trip.end_date:
            state["duration_days"] = (trip.end_date - trip.start_date).days
        if trip.nb_travelers:
            state["nb_travelers"] = trip.nb_travelers

        # Include existing activities and accommodations
        activities = [
            {"name": a.title, "estimated_cost": a.estimated_cost} for a in trip.activities
        ]
        if activities:
            state["activities"] = activities

        accommodations = [
            {"name": a.name, "price_per_night": a.price_per_night} for a in trip.accommodations
        ]
        if accommodations:
            state["accommodations"] = accommodations

        result = await budget_node(state)
        estimation = result.get("budget_estimation", {})

        PlanService.increment_ai_generation(db, current_user)
        return BudgetEstimateResponse(estimation=estimation)
    except AppError as e:
        raise create_http_exception(e) from e


@router.post(
    "/{tripId}/budget/estimate/accept",
    summary="Accept AI budget estimation",
    description="Accept the AI budget estimation and set the trip budget total",
)
async def accept_budget_estimate(
    request: AcceptEstimateRequest,
    access: Annotated[TripAccess, Depends(get_trip_editor_access)],
    db: Annotated[Session, Depends(get_db)],
):
    """Accept the AI budget estimation.

    Topic 02 (B3): writes ``Trip.budget_estimated`` only — the user's
    ``budget_target`` is preserved so the alert thresholds keep
    referencing the user's intent, not the AI guess. Bypasses
    ``TripsService.update_trip`` because that surface forbids writes
    to ``budget_estimated``.
    """
    try:
        access.trip.budget_estimated = request.budget_estimated
        db.commit()
        db.refresh(access.trip)
        NotificationService.check_and_send_budget_alert(db, access.trip)
        return {"success": True}
    except AppError as e:
        raise create_http_exception(e) from e
