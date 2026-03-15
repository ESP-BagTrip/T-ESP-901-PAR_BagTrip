from datetime import date, time
from math import ceil
from uuid import UUID

from sqlalchemy import asc
from sqlalchemy.orm import Session

from src.enums import TripStatus
from src.models.activity import Activity
from src.models.trip import Trip
from src.utils.errors import AppError


class ActivityService:
    """Service for Activity CRUD operations."""

    @staticmethod
    def _check_trip_not_completed(trip: Trip) -> None:
        if trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify activities on a completed trip.",
            )

    @staticmethod
    def create(
        db: Session,
        trip: Trip,
        title: str,
        date: date,
        description: str | None = None,
        start_time: time | None = None,
        end_time: time | None = None,
        location: str | None = None,
        category: str = "OTHER",
        estimated_cost: float | None = None,
        is_booked: bool = False,
    ) -> Activity:
        ActivityService._check_trip_not_completed(trip)
        activity = Activity(
            trip_id=trip.id,
            title=title,
            description=description,
            date=date,
            start_time=start_time,
            end_time=end_time,
            location=location,
            category=category,
            estimated_cost=estimated_cost,
            is_booked=is_booked,
        )
        db.add(activity)
        db.commit()
        db.refresh(activity)
        return activity

    @staticmethod
    def get_by_trip(db: Session, trip_id: UUID) -> list[Activity]:
        return (
            db.query(Activity)
            .filter(Activity.trip_id == trip_id)
            .order_by(asc(Activity.date), asc(Activity.start_time))
            .all()
        )

    @staticmethod
    def get_by_trip_paginated(
        db: Session, trip_id: UUID, page: int = 1, limit: int = 20
    ) -> tuple[list[Activity], int, int]:
        """Get paginated activities for a trip. Returns (items, total, total_pages)."""
        query = (
            db.query(Activity)
            .filter(Activity.trip_id == trip_id)
            .order_by(asc(Activity.date), asc(Activity.start_time))
        )
        total = query.count()
        total_pages = ceil(total / limit) if limit > 0 else 0
        items = query.offset((page - 1) * limit).limit(limit).all()
        return items, total, total_pages

    @staticmethod
    def get_by_id(db: Session, activity_id: UUID, trip_id: UUID) -> Activity:
        activity = (
            db.query(Activity)
            .filter(Activity.id == activity_id, Activity.trip_id == trip_id)
            .first()
        )
        if not activity:
            raise AppError("ACTIVITY_NOT_FOUND", 404, "Activity not found")
        return activity

    @staticmethod
    def update(
        db: Session,
        trip: Trip,
        activity_id: UUID,
        title: str | None = None,
        description: str | None = None,
        date: date | None = None,
        start_time: time | None = None,
        end_time: time | None = None,
        location: str | None = None,
        category: str | None = None,
        estimated_cost: float | None = None,
        is_booked: bool | None = None,
    ) -> Activity:
        ActivityService._check_trip_not_completed(trip)
        activity = ActivityService.get_by_id(db, activity_id, trip.id)

        if title is not None:
            activity.title = title
        if description is not None:
            activity.description = description
        if date is not None:
            activity.date = date
        if start_time is not None:
            activity.start_time = start_time
        if end_time is not None:
            activity.end_time = end_time
        if location is not None:
            activity.location = location
        if category is not None:
            activity.category = category
        if estimated_cost is not None:
            activity.estimated_cost = estimated_cost
        if is_booked is not None:
            activity.is_booked = is_booked

        db.commit()
        db.refresh(activity)
        return activity

    @staticmethod
    def delete(db: Session, trip: Trip, activity_id: UUID) -> None:
        ActivityService._check_trip_not_completed(trip)
        activity = ActivityService.get_by_id(db, activity_id, trip.id)
        db.delete(activity)
        db.commit()
