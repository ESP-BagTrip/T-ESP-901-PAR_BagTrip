from __future__ import annotations

from datetime import date, time
from math import ceil
from uuid import UUID

from sqlalchemy import asc
from sqlalchemy.orm import Session

from src.api.activities.schemas import ActivityUpdateRequest
from src.enums import TripStatus
from src.models.activity import Activity
from src.models.trip import Trip
from src.utils.errors import AppError
from src.utils.logger import logger


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
        validation_status: str = "MANUAL",
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
            validation_status=validation_status,
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
        validation_status: str | None = None,
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
        if validation_status is not None:
            activity.validation_status = validation_status

        db.commit()
        db.refresh(activity)
        return activity

    @staticmethod
    def delete(db: Session, trip: Trip, activity_id: UUID) -> None:
        ActivityService._check_trip_not_completed(trip)
        activity = ActivityService.get_by_id(db, activity_id, trip.id)
        db.delete(activity)
        db.commit()

    @staticmethod
    def batch_update(
        db: Session,
        trip: Trip,
        activity_ids: list[UUID],
        updates: ActivityUpdateRequest,
    ) -> list[Activity]:
        """Apply the same partial update to multiple activities in one transaction."""
        ActivityService._check_trip_not_completed(trip)
        results = []
        for aid in activity_ids:
            activity = ActivityService.get_by_id(db, aid, trip.id)
            if updates.title is not None:
                activity.title = updates.title
            if updates.description is not None:
                activity.description = updates.description
            if updates.date is not None:
                activity.date = updates.date
            if updates.startTime is not None:
                activity.start_time = updates.startTime
            if updates.endTime is not None:
                activity.end_time = updates.endTime
            if updates.location is not None:
                activity.location = updates.location
            if updates.category is not None:
                activity.category = updates.category
            if updates.estimatedCost is not None:
                activity.estimated_cost = updates.estimatedCost
            if updates.isBooked is not None:
                activity.is_booked = updates.isBooked
            if updates.validationStatus is not None:
                activity.validation_status = updates.validationStatus
            results.append(activity)
        db.commit()
        for a in results:
            db.refresh(a)
        return results

    @staticmethod
    async def suggest(
        db: Session,
        trip: Trip,
        day: int | None = None,
    ) -> list[dict]:
        """Generate AI activity suggestions for a trip (optionally for a specific day)."""
        from src.agent.prompts import render as render_prompt
        from src.services.llm_service import LLMService

        parts = []
        dest_name = trip.destination_name or "Unknown"
        parts.append(f"Destination: {dest_name}")
        if trip.start_date and trip.end_date:
            duration = (trip.end_date - trip.start_date).days + 1
            parts.append(f"Trip duration: {duration} days")
        if trip.nb_travelers:
            parts.append(f"Number of travelers: {trip.nb_travelers}")
        if day is not None:
            parts.append(f"Suggest activities specifically for day {day} of the trip.")

        user_prompt = "\n".join(parts)

        llm = LLMService()
        try:
            result = await llm.acall_llm(render_prompt("activity_planner"), user_prompt)
            activities = result.get("activities", [])
        except Exception as e:
            logger.error("Activity suggest LLM call failed", {"error": str(e)})
            activities = []

        return activities
