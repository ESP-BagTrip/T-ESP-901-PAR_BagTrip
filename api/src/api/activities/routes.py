from uuid import UUID

from fastapi import APIRouter, Depends, Path, Query, status
from sqlalchemy.orm import Session

from src.api.activities.schemas import (
    ActivityCreateRequest,
    ActivityListResponse,
    ActivityPaginatedResponse,
    ActivityResponse,
    ActivityUpdateRequest,
)
from src.api.auth.trip_access import TripAccess, TripRole, get_trip_access, get_trip_owner_access
from src.config.database import get_db
from src.services.activity_service import ActivityService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/trips", tags=["Activities"])


@router.post(
    "/{tripId}/activities",
    response_model=ActivityResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_activity(
    request: ActivityCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        activity = ActivityService.create(
            db=db,
            trip=access.trip,
            title=request.title,
            date=request.date,
            description=request.description,
            start_time=request.startTime,
            end_time=request.endTime,
            location=request.location,
            category=request.category or "OTHER",
            estimated_cost=request.estimatedCost,
            is_booked=request.isBooked or False,
        )
        return ActivityResponse.model_validate(activity)
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/activities", response_model=ActivityPaginatedResponse)
async def list_activities(
    page: int = Query(default=1, ge=1, description="Page number"),
    limit: int = Query(default=20, ge=1, le=100, description="Items per page"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    try:
        activities, total, total_pages = ActivityService.get_by_trip_paginated(
            db, access.trip.id, page=page, limit=limit,
        )
        items = [ActivityResponse.model_validate(a) for a in activities]
        if access.role == TripRole.VIEWER:
            for item in items:
                item.estimatedCost = None
        return ActivityPaginatedResponse(
            items=items, total=total, page=page, limit=limit, total_pages=total_pages,
        )
    except AppError as e:
        raise create_http_exception(e) from e


@router.get("/{tripId}/activities/{activityId}", response_model=ActivityResponse)
async def get_activity(
    activityId: UUID = Path(..., description="Activity ID"),
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    try:
        activity = ActivityService.get_by_id(db, activityId, access.trip.id)
        resp = ActivityResponse.model_validate(activity)
        if access.role == TripRole.VIEWER:
            resp.estimatedCost = None
        return resp
    except AppError as e:
        raise create_http_exception(e) from e


@router.put("/{tripId}/activities/{activityId}", response_model=ActivityResponse)
async def update_activity(
    request: ActivityUpdateRequest,
    activityId: UUID = Path(..., description="Activity ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        activity = ActivityService.update(
            db=db,
            trip=access.trip,
            activity_id=activityId,
            title=request.title,
            description=request.description,
            date=request.date,
            start_time=request.startTime,
            end_time=request.endTime,
            location=request.location,
            category=request.category,
            estimated_cost=request.estimatedCost,
            is_booked=request.isBooked,
        )
        return ActivityResponse.model_validate(activity)
    except AppError as e:
        raise create_http_exception(e) from e


@router.delete(
    "/{tripId}/activities/{activityId}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_activity(
    activityId: UUID = Path(..., description="Activity ID"),
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    try:
        ActivityService.delete(db, access.trip, activityId)
    except AppError as e:
        raise create_http_exception(e) from e
