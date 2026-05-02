"""Admin service — trips, travelers, shares and feedbacks domain."""

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from src.api.common.pagination import PaginationParams, paginate
from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.feedback import Feedback
from src.models.traveler import TripTraveler
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.utils.errors import AppError


def _serialize_trip_row(row) -> dict:
    trip, user_email = row
    return {
        "id": trip.id,
        "user_id": trip.user_id,
        "user_email": user_email,
        "title": trip.title,
        "origin_iata": trip.origin_iata,
        "destination_iata": trip.destination_iata,
        "destination_name": getattr(trip, "destination_name", None),
        "start_date": trip.start_date,
        "end_date": trip.end_date,
        "status": trip.status,
        "budget_target": trip.budget_target,
        "budget_estimated": trip.budget_estimated,
        "budget_actual": trip.budget_actual,
        "nb_travelers": getattr(trip, "nb_travelers", None),
        "origin": trip.origin,
        "created_at": trip.created_at,
        "updated_at": trip.updated_at,
    }


def _serialize_traveler_row(row) -> dict:
    traveler, trip_title, user_email = row
    return {
        "id": traveler.id,
        "trip_id": traveler.trip_id,
        "trip_title": trip_title,
        "user_email": user_email,
        "amadeus_traveler_ref": traveler.amadeus_traveler_ref,
        "traveler_type": traveler.traveler_type,
        "first_name": traveler.first_name,
        "last_name": traveler.last_name,
        "date_of_birth": traveler.date_of_birth,
        "gender": traveler.gender,
        "created_at": traveler.created_at,
        "updated_at": traveler.updated_at,
    }


def _serialize_trip_share_row(row) -> dict:
    share, trip_title, user_email = row
    return {
        "id": share.id,
        "trip_id": share.trip_id,
        "trip_title": trip_title,
        "user_id": share.user_id,
        "user_email": user_email,
        "role": share.role,
        "invited_at": share.invited_at,
    }


def _serialize_feedback_row(row) -> dict:
    feedback, trip_title, user_email = row
    return {
        "id": feedback.id,
        "trip_id": feedback.trip_id,
        "trip_title": trip_title,
        "user_id": feedback.user_id,
        "user_email": user_email,
        "overall_rating": feedback.overall_rating,
        "highlights": feedback.highlights,
        "lowlights": feedback.lowlights,
        "would_recommend": feedback.would_recommend,
        "created_at": feedback.created_at,
    }


class AdminTripsService:
    """Admin operations over trips, travelers, shares and feedbacks."""

    @staticmethod
    def get_all_trips(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Récupérer tous les trips avec infos user. Retourne (items, total, total_pages)."""
        query = (
            db.query(Trip, User.email.label("user_email"))
            .join(User, Trip.user_id == User.id)
            .order_by(Trip.created_at.desc())
        )
        if q:
            query = query.filter(or_(Trip.title.ilike(f"%{q}%"), User.email.ilike(f"%{q}%")))
        return paginate(query, PaginationParams.of(page, limit), _serialize_trip_row).as_tuple()

    @staticmethod
    def get_all_travelers(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les travelers."""
        query = (
            db.query(
                TripTraveler,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, TripTraveler.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(TripTraveler.created_at.desc())
        )
        return paginate(query, PaginationParams.of(page, limit), _serialize_traveler_row).as_tuple()

    @staticmethod
    def get_all_trip_shares(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les trip shares."""
        query = (
            db.query(
                TripShare,
                Trip.title.label("trip_title"),
                User.email.label("owner_email"),
            )
            .join(Trip, TripShare.trip_id == Trip.id)
            .join(User, TripShare.user_id == User.id)
            .order_by(TripShare.invited_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_trip_share_row
        ).as_tuple()

    @staticmethod
    def get_all_feedbacks(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les feedbacks."""
        query = (
            db.query(
                Feedback,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, Feedback.trip_id == Trip.id)
            .join(User, Feedback.user_id == User.id)
            .order_by(Feedback.created_at.desc())
        )
        return paginate(query, PaginationParams.of(page, limit), _serialize_feedback_row).as_tuple()

    @staticmethod
    def delete_feedback(db: Session, feedback_id) -> None:
        """Supprimer un feedback."""
        from src.models.feedback import Feedback as FeedbackModel

        feedback = db.query(FeedbackModel).filter(FeedbackModel.id == feedback_id).first()
        if not feedback:
            raise AppError("FEEDBACK_NOT_FOUND", 404, "Feedback not found")
        db.delete(feedback)
        db.commit()

    @staticmethod
    def get_trip_detail(db: Session, trip_id) -> dict:
        """Get detailed trip info with sub-entity counts."""
        result = (
            db.query(Trip, User.email.label("user_email"))
            .join(User, Trip.user_id == User.id)
            .filter(Trip.id == trip_id)
            .first()
        )
        if not result:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        trip, user_email = result
        activities_count = (
            db.query(func.count(Activity.id)).filter(Activity.trip_id == trip_id).scalar() or 0
        )
        accommodations_count = (
            db.query(func.count(Accommodation.id)).filter(Accommodation.trip_id == trip_id).scalar()
            or 0
        )
        shares_count = (
            db.query(func.count(TripShare.id)).filter(TripShare.trip_id == trip_id).scalar() or 0
        )
        return {
            "id": trip.id,
            "user_id": trip.user_id,
            "user_email": user_email,
            "title": trip.title,
            "origin_iata": trip.origin_iata,
            "destination_iata": trip.destination_iata,
            "destination_name": getattr(trip, "destination_name", None),
            "start_date": trip.start_date,
            "end_date": trip.end_date,
            "status": trip.status,
            "budget_target": trip.budget_target,
            "budget_estimated": trip.budget_estimated,
            "budget_actual": trip.budget_actual,
            "nb_travelers": getattr(trip, "nb_travelers", None),
            "origin": trip.origin,
            "archived_at": getattr(trip, "archived_at", None),
            "activities_count": activities_count,
            "accommodations_count": accommodations_count,
            "shares_count": shares_count,
            "created_at": trip.created_at,
            "updated_at": trip.updated_at,
        }

    @staticmethod
    def update_trip(db: Session, trip_id, updates: dict) -> None:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        # Topic 02 — admin can move the user's target but not the AI
        # estimation (which is mutated through the dedicated accept
        # endpoint) and not the actual (computed at runtime).
        allowed = {
            "title",
            "status",
            "start_date",
            "end_date",
            "destination_name",
            "budget_target",
            "nb_travelers",
        }
        for key, value in updates.items():
            if key in allowed:
                setattr(trip, key, value)
        db.commit()

    @staticmethod
    def delete_trip(db: Session, trip_id) -> None:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        db.delete(trip)
        db.commit()

    @staticmethod
    def archive_trip(db: Session, trip_id) -> None:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip:
            raise AppError("NOT_FOUND", 404, "Trip not found")
        trip.archived_at = func.now()
        db.commit()

    @staticmethod
    def delete_share(db: Session, trip_id, share_id) -> None:
        share = (
            db.query(TripShare)
            .filter(TripShare.id == share_id, TripShare.trip_id == trip_id)
            .first()
        )
        if not share:
            raise AppError("NOT_FOUND", 404, "Share not found")
        db.delete(share)
        db.commit()
