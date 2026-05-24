"""Admin service — users + traveler profiles domain."""

import csv
import io

from sqlalchemy import func
from sqlalchemy.orm import Session

from src.api.common.pagination import PaginationParams, paginate
from src.models.booking_intent import BookingIntent
from src.models.traveler_profile import TravelerProfile
from src.models.trip import Trip
from src.models.user import User
from src.utils.errors import AppError


def _serialize_user(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "plan": user.plan or "FREE",
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }


def _serialize_traveler_profile_row(row) -> dict:
    profile, user_email = row
    return {
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


class AdminUsersService:
    """Admin operations over users and traveler profiles."""

    @staticmethod
    def get_all_users(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Récupérer tous les utilisateurs. Retourne (items, total, total_pages)."""
        query = db.query(User).order_by(User.created_at.desc())
        if q:
            query = query.filter(User.email.ilike(f"%{q}%"))
        return paginate(query, PaginationParams.of(page, limit), _serialize_user).as_tuple()

    @staticmethod
    def get_all_traveler_profiles(
        db: Session, page: int = 1, limit: int = 10, q: str | None = None
    ) -> tuple[list[dict], int, int]:
        """Retourne (items, total, total_pages) pour tous les traveler profiles."""
        query = (
            db.query(TravelerProfile, User.email.label("user_email"))
            .join(User, TravelerProfile.user_id == User.id)
            .order_by(TravelerProfile.created_at.desc())
        )
        return paginate(
            query, PaginationParams.of(page, limit), _serialize_traveler_profile_row
        ).as_tuple()

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
