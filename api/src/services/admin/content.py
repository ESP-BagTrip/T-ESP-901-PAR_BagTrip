"""Admin service — CRUD over activities, accommodations, baggage and budget items."""

from sqlalchemy.orm import Session

from src.api.common.pagination import PaginationParams, paginate
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.budget_item import BudgetItem
from src.models.trip import Trip
from src.models.user import User
from src.utils.errors import AppError


def _serialize_accommodation_row(row) -> dict:
    accommodation, trip_title, user_email = row
    return {
        "id": accommodation.id,
        "trip_id": accommodation.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "name": accommodation.name,
        "address": accommodation.address,
        "check_in": accommodation.check_in,
        "check_out": accommodation.check_out,
        "price_per_night": (
            float(accommodation.price_per_night) if accommodation.price_per_night else None
        ),
        "currency": accommodation.currency,
        "booking_reference": accommodation.booking_reference,
        "created_at": accommodation.created_at,
        "updated_at": accommodation.updated_at,
    }


def _serialize_baggage_row(row) -> dict:
    baggage_item, trip_title, user_email = row
    return {
        "id": baggage_item.id,
        "trip_id": baggage_item.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "name": baggage_item.name,
        "category": baggage_item.category,
        "quantity": baggage_item.quantity,
        "is_packed": baggage_item.is_packed,
        "created_at": baggage_item.created_at,
        "updated_at": baggage_item.updated_at,
    }


def _serialize_activity_row(row) -> dict:
    activity, trip_title, user_email = row
    return {
        "id": activity.id,
        "trip_id": activity.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "title": activity.title,
        "description": activity.description,
        "date": activity.date,
        "start_time": activity.start_time,
        "end_time": activity.end_time,
        "location": activity.location,
        "category": activity.category,
        "estimated_cost": float(activity.estimated_cost) if activity.estimated_cost else None,
        "is_booked": activity.is_booked,
        "created_at": activity.created_at,
        "updated_at": activity.updated_at,
    }


def _serialize_budget_row(row) -> dict:
    budget_item, trip_title, user_email = row
    return {
        "id": budget_item.id,
        "trip_id": budget_item.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "label": budget_item.label,
        "amount": float(budget_item.amount),
        "category": budget_item.category,
        "date": budget_item.date,
        "is_planned": budget_item.is_planned,
        "created_at": budget_item.created_at,
        "updated_at": budget_item.updated_at,
    }


class AdminContentService:
    """Admin CRUD over trip content (activities, accommodations, baggage, budget)."""

    @staticmethod
    def get_all_accommodations(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les hébergements."""
        query = (
            db.query(
                Accommodation,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, Accommodation.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(Accommodation.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_accommodation_row
        ).as_tuple()

    @staticmethod
    def get_all_baggage_items(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les baggage items."""
        query = (
            db.query(
                BaggageItem,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, BaggageItem.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(BaggageItem.created_at.desc())
        )
        return paginate(query, PaginationParams.of(page, limit), _serialize_baggage_row).as_tuple()

    @staticmethod
    def get_all_activities(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour toutes les activités."""
        query = (
            db.query(
                Activity,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, Activity.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(Activity.created_at.desc())
        )
        return paginate(query, PaginationParams.of(page, limit), _serialize_activity_row).as_tuple()

    @staticmethod
    def get_all_budget_items(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les budget items."""
        query = (
            db.query(
                BudgetItem,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, BudgetItem.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(BudgetItem.created_at.desc())
        )
        return paginate(query, PaginationParams.of(page, limit), _serialize_budget_row).as_tuple()

    @staticmethod
    def create_activity(db: Session, trip_id, data: dict):
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        activity = Activity(trip_id=trip_id, **data)
        db.add(activity)
        db.commit()
        db.refresh(activity)
        return activity

    @staticmethod
    def update_activity(db: Session, trip_id, activity_id, updates: dict) -> None:
        activity = (
            db.query(Activity)
            .filter(Activity.id == activity_id, Activity.trip_id == trip_id)
            .first()
        )
        if not activity:
            raise AppError("NOT_FOUND", 404, "Activity not found")
        for key, value in updates.items():
            setattr(activity, key, value)
        db.commit()

    @staticmethod
    def delete_activity(db: Session, trip_id, activity_id) -> None:
        activity = (
            db.query(Activity)
            .filter(Activity.id == activity_id, Activity.trip_id == trip_id)
            .first()
        )
        if not activity:
            raise AppError("NOT_FOUND", 404, "Activity not found")
        db.delete(activity)
        db.commit()

    @staticmethod
    def create_accommodation(db: Session, trip_id, data: dict):
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        acc = Accommodation(trip_id=trip_id, **data)
        db.add(acc)
        db.commit()
        db.refresh(acc)
        return acc

    @staticmethod
    def update_accommodation(db: Session, trip_id, acc_id, updates: dict) -> None:
        acc = (
            db.query(Accommodation)
            .filter(Accommodation.id == acc_id, Accommodation.trip_id == trip_id)
            .first()
        )
        if not acc:
            raise AppError("NOT_FOUND", 404, "Accommodation not found")
        for key, value in updates.items():
            setattr(acc, key, value)
        db.commit()

    @staticmethod
    def delete_accommodation(db: Session, trip_id, acc_id) -> None:
        acc = (
            db.query(Accommodation)
            .filter(Accommodation.id == acc_id, Accommodation.trip_id == trip_id)
            .first()
        )
        if not acc:
            raise AppError("NOT_FOUND", 404, "Accommodation not found")
        db.delete(acc)
        db.commit()

    @staticmethod
    def delete_budget_item(db: Session, trip_id, item_id) -> None:
        item = (
            db.query(BudgetItem)
            .filter(BudgetItem.id == item_id, BudgetItem.trip_id == trip_id)
            .first()
        )
        if not item:
            raise AppError("NOT_FOUND", 404, "Budget item not found")
        db.delete(item)
        db.commit()

    @staticmethod
    def delete_baggage_item(db: Session, trip_id, item_id) -> None:
        item = (
            db.query(BaggageItem)
            .filter(BaggageItem.id == item_id, BaggageItem.trip_id == trip_id)
            .first()
        )
        if not item:
            raise AppError("NOT_FOUND", 404, "Baggage item not found")
        db.delete(item)
        db.commit()
