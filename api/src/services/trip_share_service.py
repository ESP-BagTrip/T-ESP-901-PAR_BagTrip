"""Service pour la gestion des partages de trips."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.enums import ShareRole, TripStatus
from src.models.trip import Trip
from src.models.trip_share import TripShare
from src.models.user import User
from src.utils.errors import AppError


class TripShareService:
    """Service pour les opérations CRUD sur les partages de trips."""

    @staticmethod
    def _check_trip_not_completed(db: Session, trip_id: UUID) -> None:
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if trip and trip.status == TripStatus.COMPLETED:
            raise AppError(
                "TRIP_COMPLETED",
                403,
                "Cannot modify shares on a completed trip.",
            )

    @staticmethod
    def create_share(db: Session, trip_id: UUID, owner_user_id: UUID, email: str) -> dict:
        """Inviter un utilisateur par email à rejoindre un trip."""
        TripShareService._check_trip_not_completed(db, trip_id)
        # Resolve user by email
        user = db.query(User).filter(User.email == email).first()
        if not user:
            raise AppError("USER_NOT_FOUND", 404, "User not found")

        # No self-sharing
        if user.id == owner_user_id:
            raise AppError("SELF_SHARING", 400, "Cannot share a trip with yourself")

        # Check not already shared
        existing = (
            db.query(TripShare)
            .filter(TripShare.trip_id == trip_id, TripShare.user_id == user.id)
            .first()
        )
        if existing:
            raise AppError("ALREADY_SHARED", 409, "Trip already shared with this user")

        # Check quota based on owner's plan
        from src.services.plan_service import PlanService

        owner = db.query(User).filter(User.id == owner_user_id).first()
        limit = PlanService.get_share_limit(owner) if owner else 2
        share_count = db.query(TripShare).filter(TripShare.trip_id == trip_id).count()
        if limit is not None and share_count >= limit:
            raise AppError(
                "SHARE_QUOTA_EXCEEDED",
                402,
                f"Maximum {limit} shares reached. Upgrade for more.",
            )

        # Create share
        share = TripShare(trip_id=trip_id, user_id=user.id, role=ShareRole.VIEWER)
        db.add(share)
        db.commit()
        db.refresh(share)

        return {
            "id": share.id,
            "trip_id": share.trip_id,
            "user_id": share.user_id,
            "role": share.role,
            "invited_at": share.invited_at,
            "user_email": user.email,
            "user_full_name": user.full_name,
        }

    @staticmethod
    def get_shares_by_trip(db: Session, trip_id: UUID) -> list[dict]:
        """Récupérer tous les partages d'un trip."""
        shares = (
            db.query(TripShare, User.email.label("user_email"), User.full_name.label("user_full_name"))
            .join(User, TripShare.user_id == User.id)
            .filter(TripShare.trip_id == trip_id)
            .all()
        )
        return [
            {
                "id": share.id,
                "trip_id": share.trip_id,
                "user_id": share.user_id,
                "role": share.role,
                "invited_at": share.invited_at,
                "user_email": user_email,
                "user_full_name": user_full_name,
            }
            for share, user_email, user_full_name in shares
        ]

    @staticmethod
    def delete_share(db: Session, share_id: UUID, trip_id: UUID) -> None:
        """Révoquer un partage."""
        TripShareService._check_trip_not_completed(db, trip_id)
        share = (
            db.query(TripShare)
            .filter(TripShare.id == share_id, TripShare.trip_id == trip_id)
            .first()
        )
        if not share:
            raise AppError("SHARE_NOT_FOUND", 404, "Share not found")

        db.delete(share)
        db.commit()
