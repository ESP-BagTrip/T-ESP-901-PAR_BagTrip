"""Service pour la gestion des conversations."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.conversation import Conversation


class ConversationService:
    """Service pour les opérations CRUD sur les conversations."""

    @staticmethod
    def create_conversation(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
        title: str | None = None,
    ) -> Conversation:
        """Créer une nouvelle conversation (accès vérifié par la dependency)."""
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
        """Récupérer une conversation par ID."""
        return (
            db.query(Conversation)
            .filter(Conversation.id == conversation_id, Conversation.user_id == user_id)
            .first()
        )

    @staticmethod
    def get_conversations_by_trip(
        db: Session,
        trip_id: UUID,
        user_id: UUID,
    ) -> list[Conversation]:
        """Récupérer toutes les conversations d'un trip (accès vérifié par la dependency)."""
        return (
            db.query(Conversation)
            .filter(Conversation.trip_id == trip_id, Conversation.user_id == user_id)
            .order_by(Conversation.created_at.desc())
            .all()
        )
