"""Service pour la gestion des conversations."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.conversation import Conversation
from src.services.trips_service import TripsService
from src.utils.errors import AppError


class ConversationService:
    """Service pour les opérations CRUD sur les conversations."""

    @staticmethod
    def create_conversation(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        title: str | None = None,
    ) -> Conversation:
        """
        Créer une nouvelle conversation pour un trip.
        - Vérifier que le trip appartient à l'utilisateur
        - Créer la conversation
        - Retourner la conversation créée
        """
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        conversation = Conversation(
            trip_id=trip_id,
            user_id=user_id,
            title=title,
        )
        db.add(conversation)
        db.commit()
        db.refresh(conversation)
        return conversation

    @staticmethod
    def get_conversation_by_id(
        db: Session,
        conversation_id: UUID,
        user_id: UUID,
    ) -> Conversation | None:
        """
        Récupérer une conversation par ID.
        - Vérifier que la conversation appartient à l'utilisateur
        - Retourner None si non trouvée ou non autorisée
        """
        conversation = (
            db.query(Conversation)
            .filter(Conversation.id == conversation_id, Conversation.user_id == user_id)
            .first()
        )
        return conversation

    @staticmethod
    def get_conversations_by_trip(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
    ) -> list[Conversation]:
        """
        Récupérer toutes les conversations d'un trip.
        - Vérifier que le trip appartient à l'utilisateur
        - Retourner liste triée par created_at DESC
        """
        # Vérifier que le trip existe et appartient à l'utilisateur
        trip = TripsService.get_trip_by_id(db, trip_id, user_id)
        if not trip:
            raise AppError("TRIP_NOT_FOUND", 404, "Trip not found")

        return (
            db.query(Conversation)
            .filter(Conversation.trip_id == trip_id, Conversation.user_id == user_id)
            .order_by(Conversation.created_at.desc())
            .all()
        )
