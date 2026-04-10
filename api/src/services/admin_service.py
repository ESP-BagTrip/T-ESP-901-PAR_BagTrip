"""Service pour les opérations admin (sans filtrage par utilisateur)."""

import csv
import io
from math import ceil

from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from src.models.accommodation import Accommodation
from src.models.activity import Activity
from src.models.baggage_item import BaggageItem
from src.models.booking_intent import BookingIntent
from src.models.budget_item import BudgetItem
from src.models.feedback import Feedback
from src.models.flight_order import FlightOrder
from src.models.flight_search import FlightSearch
from src.models.notification import Notification
from src.models.traveler import TripTraveler
from src.models.traveler_profile import TravelerProfile
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.utils.errors import AppError


class AdminService:
    """Service pour les opérations admin."""

    @staticmethod
    def get_all_users(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les utilisateurs.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête pour obtenir tous les utilisateurs
        query = db.query(User).order_by(User.created_at.desc())

        if q:
            query = query.filter(User.email.ilike(f"%{q}%"))

        # Compter le total
        total = query.count()

        # Paginer
        users = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for user in users:
            items.append(
                {
                    "id": user.id,
                    "email": user.email,
                    "plan": user.plan or "FREE",
                    "created_at": user.created_at,
                    "updated_at": user.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_trips(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les trips avec informations utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec join pour obtenir l'email de l'utilisateur
        query = (
            db.query(
                Trip,
                User.email.label("user_email"),
            )
            .join(User, Trip.user_id == User.id)
            .order_by(Trip.created_at.desc())
        )

        if q:
            query = query.filter(or_(Trip.title.ilike(f"%{q}%"), User.email.ilike(f"%{q}%")))

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for trip, user_email in results:
            items.append(
                {
                    "id": trip.id,
                    "user_id": trip.user_id,
                    "user_email": user_email,
                    "title": trip.title,
                    "origin_iata": trip.origin_iata,
                    "destination_iata": trip.destination_iata,
                    "start_date": trip.start_date,
                    "end_date": trip.end_date,
                    "status": trip.status,
                    "budget_total": trip.budget_total,
                    "origin": trip.origin,
                    "created_at": trip.created_at,
                    "updated_at": trip.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_travelers(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les travelers avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec joins pour obtenir trip title et user email
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

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for traveler, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_flight_bookings(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les flight bookings avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        # Calculer l'offset
        offset = (page - 1) * limit

        # Requête avec joins pour obtenir trip title et user email
        query = (
            db.query(
                FlightOrder,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, FlightOrder.trip_id == Trip.id)
            .join(User, Trip.user_id == User.id)
            .order_by(FlightOrder.created_at.desc())
        )

        # Compter le total
        total = query.count()

        # Paginer
        results = query.offset(offset).limit(limit).all()

        # Construire les items
        items = []
        for order, trip_title, user_email in results:
            items.append(
                {
                    "id": order.id,
                    "trip_id": order.trip_id,
                    "trip_title": trip_title,
                    "user_email": user_email,
                    "flight_offer_id": order.flight_offer_id,
                    "booking_intent_id": order.booking_intent_id,
                    "amadeus_flight_order_id": order.amadeus_flight_order_id,
                    "status": order.status,
                    "booking_reference": order.booking_reference,
                    "created_at": order.created_at,
                    "updated_at": order.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_traveler_profiles(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les profils voyageurs avec informations utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

        query = (
            db.query(
                TravelerProfile,
                User.email.label("user_email"),
            )
            .join(User, TravelerProfile.user_id == User.id)
            .order_by(TravelerProfile.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for profile, user_email in results:
            items.append(
                {
                    "id": profile.id,
                    "user_id": profile.user_id,
                    "user_email": user_email,
                    "travel_types": profile.travel_types,
                    "travel_style": profile.travel_style,
                    "budget": profile.budget,
                    "companions": profile.companions,
                    "is_completed": profile.is_completed,
                    "created_at": profile.created_at,
                    "updated_at": profile.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_booking_intents(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les booking intents avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

        query = (
            db.query(
                BookingIntent,
                Trip.title.label("trip_title"),
                User.email.label("user_email"),
            )
            .join(Trip, BookingIntent.trip_id == Trip.id)
            .join(User, BookingIntent.user_id == User.id)
            .order_by(BookingIntent.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for intent, trip_title, user_email in results:
            items.append(
                {
                    "id": intent.id,
                    "user_id": intent.user_id,
                    "user_email": user_email,
                    "trip_id": intent.trip_id,
                    "trip_title": trip_title,
                    "type": intent.type,
                    "status": intent.status,
                    "amount": float(intent.amount),
                    "currency": intent.currency,
                    "stripe_payment_intent_id": intent.stripe_payment_intent_id,
                    "created_at": intent.created_at,
                    "updated_at": intent.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_accommodations(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les hébergements avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for accommodation, trip_title, user_email in results:
            items.append(
                {
                    "id": accommodation.id,
                    "trip_id": accommodation.trip_id,
                    "trip_title": trip_title,
                    "user_email": user_email,
                    "name": accommodation.name,
                    "address": accommodation.address,
                    "check_in": accommodation.check_in,
                    "check_out": accommodation.check_out,
                    "price_per_night": float(accommodation.price_per_night)
                    if accommodation.price_per_night
                    else None,
                    "currency": accommodation.currency,
                    "booking_reference": accommodation.booking_reference,
                    "created_at": accommodation.created_at,
                    "updated_at": accommodation.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_baggage_items(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les éléments de bagage avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for baggage_item, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_activities(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les activités avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for activity, trip_title, user_email in results:
            items.append(
                {
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
                    "estimated_cost": float(activity.estimated_cost)
                    if activity.estimated_cost
                    else None,
                    "is_booked": activity.is_booked,
                    "created_at": activity.created_at,
                    "updated_at": activity.updated_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_budget_items(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer tous les budget items avec informations trip et utilisateur.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for budget_item, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_trip_shares(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Récupérer tous les partages de trips."""
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for share, trip_title, user_email in results:
            items.append(
                {
                    "id": share.id,
                    "trip_id": share.trip_id,
                    "trip_title": trip_title,
                    "user_id": share.user_id,
                    "user_email": user_email,
                    "role": share.role,
                    "invited_at": share.invited_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_feedbacks(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Récupérer tous les feedbacks."""
        offset = (page - 1) * limit

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

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for feedback, trip_title, user_email in results:
            items.append(
                {
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
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

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
    def update_user_plan(db: Session, user_id, plan: str) -> None:
        """Update a user's plan."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("USER_NOT_FOUND", 404, "User not found")
        if plan not in ("FREE", "PREMIUM", "ADMIN"):
            raise AppError("INVALID_PLAN", 400, "Plan must be FREE, PREMIUM or ADMIN")
        user.plan = plan
        db.commit()

    @staticmethod
    def get_all_notifications(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Récupérer toutes les notifications avec informations utilisateur et trip."""
        offset = (page - 1) * limit

        query = (
            db.query(
                Notification,
                User.email.label("user_email"),
                Trip.title.label("trip_title"),
            )
            .join(User, Notification.user_id == User.id)
            .outerjoin(Trip, Notification.trip_id == Trip.id)
            .order_by(Notification.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for notif, user_email, trip_title in results:
            items.append(
                {
                    "id": notif.id,
                    "user_id": notif.user_id,
                    "user_email": user_email,
                    "trip_id": notif.trip_id,
                    "trip_title": trip_title,
                    "type": notif.type,
                    "title": notif.title,
                    "body": notif.body,
                    "is_read": notif.is_read,
                    "sent_at": notif.sent_at,
                    "created_at": notif.created_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    @staticmethod
    def get_all_flight_searches(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """
        Récupérer toutes les recherches de vols avec informations trip.
        Retourne (items, total, total_pages).
        """
        offset = (page - 1) * limit

        query = (
            db.query(
                FlightSearch,
                Trip.title.label("trip_title"),
            )
            .join(Trip, FlightSearch.trip_id == Trip.id)
            .order_by(FlightSearch.created_at.desc())
        )

        total = query.count()
        results = query.offset(offset).limit(limit).all()

        items = []
        for search, trip_title in results:
            items.append(
                {
                    "id": search.id,
                    "trip_id": search.trip_id,
                    "trip_title": trip_title,
                    "origin_iata": search.origin_iata,
                    "destination_iata": search.destination_iata,
                    "departure_date": search.departure_date,
                    "return_date": search.return_date,
                    "adults": search.adults,
                    "children": search.children,
                    "travel_class": search.travel_class,
                    "created_at": search.created_at,
                }
            )

        total_pages = ceil(total / limit) if limit > 0 else 0
        return items, total, total_pages

    # ──────────────────────── User Management ────────────────────────

    @staticmethod
    def get_user_detail(db: Session, user_id) -> dict:
        """Get detailed user info with trip/booking counts."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        trips_count = db.query(func.count(Trip.id)).filter(Trip.user_id == user_id).scalar() or 0
        bookings_count = (
            db.query(func.count(BookingIntent.id)).filter(BookingIntent.user_id == user_id).scalar()
            or 0
        )
        return {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "phone": user.phone,
            "plan": user.plan or "FREE",
            "plan_expires_at": user.plan_expires_at,
            "ai_generations_count": user.ai_generations_count or 0,
            "ai_generations_reset_at": user.ai_generations_reset_at,
            "banned_at": getattr(user, "banned_at", None),
            "ban_reason": getattr(user, "ban_reason", None),
            "deleted_at": getattr(user, "deleted_at", None),
            "trips_count": trips_count,
            "bookings_count": bookings_count,
            "created_at": user.created_at,
            "updated_at": user.updated_at,
        }

    @staticmethod
    def update_user(db: Session, user_id, updates: dict) -> None:
        """Update user fields (email, full_name, phone, plan, plan_expires_at)."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        allowed = {"email", "full_name", "phone", "plan", "plan_expires_at"}
        for key, value in updates.items():
            if key in allowed:
                setattr(user, key, value)
        db.commit()

    @staticmethod
    def reset_ai_quota(db: Session, user_id) -> None:
        """Reset the AI generation counter to 0."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        user.ai_generations_count = 0
        user.ai_generations_reset_at = func.now()
        db.commit()

    @staticmethod
    def ban_user(db: Session, user_id, reason: str = "") -> None:
        """Set banned_at timestamp on a user."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        user.banned_at = func.now()
        user.ban_reason = reason
        db.commit()

    @staticmethod
    def unban_user(db: Session, user_id) -> None:
        """Clear banned_at on a user."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        user.banned_at = None
        user.ban_reason = None
        db.commit()

    @staticmethod
    def delete_user(db: Session, user_id) -> None:
        """Soft-delete a user by setting deleted_at."""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise AppError("NOT_FOUND", 404, "User not found")
        user.deleted_at = func.now()
        db.commit()

    @staticmethod
    def bulk_update_plan(db: Session, user_ids: list, plan: str) -> int:
        """Bulk update plan for multiple users."""
        count = (
            db.query(User)
            .filter(User.id.in_(user_ids))
            .update({"plan": plan}, synchronize_session="fetch")
        )
        db.commit()
        return count

    @staticmethod
    def bulk_ban(db: Session, user_ids: list, reason: str = "") -> int:
        """Bulk ban multiple users."""
        count = (
            db.query(User)
            .filter(User.id.in_(user_ids))
            .update({"banned_at": func.now(), "ban_reason": reason}, synchronize_session="fetch")
        )
        db.commit()
        return count

    # ──────────────────────── Booking Management ────────────────────────

    @staticmethod
    def get_booking_intent_detail(db: Session, intent_id) -> dict:
        """Get detailed booking intent info."""
        result = (
            db.query(BookingIntent, User.email.label("user_email"), Trip.title.label("trip_title"))
            .join(User, BookingIntent.user_id == User.id)
            .join(Trip, BookingIntent.trip_id == Trip.id)
            .filter(BookingIntent.id == intent_id)
            .first()
        )
        if not result:
            raise AppError("NOT_FOUND", 404, "Booking intent not found")
        bi, user_email, trip_title = result
        return {
            "id": bi.id,
            "user_id": bi.user_id,
            "user_email": user_email,
            "trip_id": bi.trip_id,
            "trip_title": trip_title,
            "type": bi.type,
            "status": bi.status,
            "amount": float(bi.amount) if bi.amount else 0,
            "currency": bi.currency or "EUR",
            "stripe_payment_intent_id": bi.stripe_payment_intent_id,
            "stripe_charge_id": getattr(bi, "stripe_charge_id", None),
            "amadeus_order_id": getattr(bi, "amadeus_order_id", None),
            "last_error": getattr(bi, "last_error", None),
            "created_at": bi.created_at,
            "updated_at": bi.updated_at,
        }

    @staticmethod
    def force_booking_status(db: Session, intent_id, new_status: str) -> None:
        """Force a booking intent status (admin bypass — no state machine validation)."""
        bi = db.query(BookingIntent).filter(BookingIntent.id == intent_id).first()
        if not bi:
            raise AppError("NOT_FOUND", 404, "Booking intent not found")
        bi.status = new_status
        db.commit()

    # ──────────────────────── Trip Management ────────────────────────

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
            "budget_total": trip.budget_total,
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
        allowed = {
            "title",
            "status",
            "start_date",
            "end_date",
            "destination_name",
            "budget_total",
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

    # ──────────────────────── Exports ────────────────────────

    @staticmethod
    def export_users_csv(db: Session) -> str:
        """Export all users as CSV string."""
        users = db.query(User).order_by(User.created_at.desc()).all()
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["id", "email", "plan", "created_at", "updated_at"])
        for user in users:
            writer.writerow(
                [
                    str(user.id),
                    user.email,
                    user.plan or "FREE",
                    user.created_at.isoformat() if user.created_at else "",
                    user.updated_at.isoformat() if user.updated_at else "",
                ]
            )
        return output.getvalue()

    @staticmethod
    def get_dashboard_metrics(db: Session) -> dict:
        """Get dashboard KPI metrics."""
        total_users = db.query(func.count(User.id)).scalar() or 0

        active_users = db.query(func.count(func.distinct(Trip.user_id))).scalar() or 0
        inactive_users = total_users - active_users

        total_trips = db.query(func.count(Trip.id)).scalar() or 0

        total_revenue = (
            db.query(func.coalesce(func.sum(BookingIntent.amount), 0))
            .filter(BookingIntent.status == "CAPTURED")
            .scalar()
        )

        total_feedbacks = db.query(func.count(Feedback.id)).scalar() or 0
        pending_feedbacks = total_feedbacks

        avg_rating = db.query(func.avg(Feedback.overall_rating)).scalar()

        return {
            "totalUsers": total_users,
            "activeUsers": active_users,
            "inactiveUsers": inactive_users,
            "totalTrips": total_trips,
            "totalRevenue": float(total_revenue),
            "totalFeedbacks": total_feedbacks,
            "pendingFeedbacks": pending_feedbacks,
            "averageRating": round(float(avg_rating), 1) if avg_rating else 0,
        }

    @staticmethod
    def get_users_chart(db: Session, period: str = "month") -> list[dict]:
        """User registrations grouped by period."""
        if period == "week":
            trunc = func.date_trunc("day", User.created_at)
        elif period == "year":
            trunc = func.date_trunc("month", User.created_at)
        else:
            trunc = func.date_trunc("week", User.created_at)

        rows = (
            db.query(trunc.label("date"), func.count(User.id).label("value"))
            .group_by(trunc)
            .order_by(trunc)
            .all()
        )
        return [
            {
                "name": row.date.strftime("%Y-%m-%d"),
                "value": row.value,
                "date": row.date.strftime("%Y-%m-%d"),
            }
            for row in rows
        ]

    @staticmethod
    def get_revenue_chart(db: Session, period: str = "month") -> list[dict]:
        """Revenue grouped by period (captured booking intents)."""
        if period == "week":
            trunc = func.date_trunc("day", BookingIntent.created_at)
        elif period == "year":
            trunc = func.date_trunc("month", BookingIntent.created_at)
        else:
            trunc = func.date_trunc("week", BookingIntent.created_at)

        rows = (
            db.query(
                trunc.label("date"),
                func.coalesce(func.sum(BookingIntent.amount), 0).label("value"),
            )
            .filter(BookingIntent.status == "CAPTURED")
            .group_by(trunc)
            .order_by(trunc)
            .all()
        )
        return [
            {
                "name": row.date.strftime("%Y-%m-%d"),
                "value": float(row.value),
                "date": row.date.strftime("%Y-%m-%d"),
            }
            for row in rows
        ]

    @staticmethod
    def get_feedbacks_chart(db: Session) -> list[dict]:
        """Feedbacks count grouped by rating."""
        rows = (
            db.query(
                Feedback.overall_rating.label("rating"),
                func.count(Feedback.id).label("count"),
            )
            .group_by(Feedback.overall_rating)
            .order_by(Feedback.overall_rating)
            .all()
        )
        return [
            {"name": f"{row.rating} étoile{'s' if row.rating > 1 else ''}", "value": row.count}
            for row in rows
        ]
