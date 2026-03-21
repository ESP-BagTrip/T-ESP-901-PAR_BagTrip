"""Service pour la gestion des feedbacks."""

from uuid import UUID

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from src.enums import TripStatus
from src.models.feedback import Feedback
from src.models.trip import Trip
from src.utils.errors import AppError


class FeedbackService:
    """Service pour les opérations CRUD sur les feedbacks."""

    @staticmethod
    def create_feedback(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        overall_rating: int,
        highlights: str | None,
        lowlights: str | None,
        would_recommend: bool,
        ai_experience_rating: int | None = None,
    ) -> Feedback:
        """Créer un feedback pour un trip terminé."""
        # Check trip is COMPLETED
        trip = db.query(Trip).filter(Trip.id == trip_id).first()
        if not trip or trip.status != TripStatus.COMPLETED:
            raise AppError(
                "TRIP_NOT_COMPLETED", 400, "Feedback can only be submitted for completed trips"
            )

        # Validate rating
        if not 1 <= overall_rating <= 5:
            raise AppError("INVALID_RATING", 400, "Rating must be between 1 and 5")

        # Check uniqueness
        existing = (
            db.query(Feedback)
            .filter(Feedback.trip_id == trip_id, Feedback.user_id == user_id)
            .first()
        )
        if existing:
            raise AppError("FEEDBACK_EXISTS", 409, "You have already submitted feedback for this trip")

        feedback = Feedback(
            trip_id=trip_id,
            user_id=user_id,
            overall_rating=overall_rating,
            highlights=highlights,
            lowlights=lowlights,
            would_recommend=would_recommend,
            ai_experience_rating=ai_experience_rating,
        )
        db.add(feedback)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise AppError("FEEDBACK_EXISTS", 409, "You have already submitted feedback for this trip")
        db.refresh(feedback)
        return feedback

    @staticmethod
    def get_feedbacks_by_trip(db: Session, trip_id: UUID) -> list[Feedback]:
        """Récupérer tous les feedbacks d'un trip."""
        return (
            db.query(Feedback)
            .filter(Feedback.trip_id == trip_id)
            .order_by(Feedback.created_at.desc())
            .all()
        )

    @staticmethod
    def get_user_feedback(db: Session, trip_id: UUID, user_id: UUID) -> Feedback | None:
        """Récupérer le feedback d'un utilisateur pour un trip."""
        return (
            db.query(Feedback)
            .filter(Feedback.trip_id == trip_id, Feedback.user_id == user_id)
            .first()
        )
