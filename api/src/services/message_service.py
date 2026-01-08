"""Service pour la gestion des messages."""

from uuid import UUID

from sqlalchemy.orm import Session

from src.models.conversation import Conversation
from src.models.message import Message
from src.utils.errors import AppError


class MessageService:
    """Service pour les opérations CRUD sur les messages."""

    VALID_ROLES = {"user", "assistant", "tool"}

    @staticmethod
    def create_message(
        db: Session,
        conversation_id: UUID,
        role: str,
        content: str,
        message_metadata: dict | None = None,
    ) -> Message:
        """
        Créer un nouveau message dans une conversation.
        - Valider role (user, assistant, tool)
        - Vérifier que la conversation existe
        - Créer le message
        - Retourner le message créé
        """
        # Valider le role
        if role not in MessageService.VALID_ROLES:
            raise AppError(
                "INVALID_ROLE",
                400,
                f"Invalid role: {role}. Must be one of {MessageService.VALID_ROLES}",
            )

        # Vérifier que la conversation existe
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if not conversation:
            raise AppError("CONVERSATION_NOT_FOUND", 404, "Conversation not found")

        message = Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
            message_metadata=message_metadata,
        )
        db.add(message)
        db.commit()
        db.refresh(message)
        return message

    @staticmethod
    def get_messages_by_conversation(
        db: Session,
        conversation_id: UUID,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Message]:
        """
        Récupérer les messages d'une conversation.
        - Pagination avec limit/offset
        - Tri par created_at ASC (chronologique)
        - Retourner liste de messages
        """
        return (
            db.query(Message)
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.asc())
            .limit(limit)
            .offset(offset)
            .all()
        )

    @staticmethod
    def get_message_count_by_conversation(db: Session, conversation_id: UUID) -> int:
        """
        Compter le nombre total de messages dans une conversation.
        Utile pour la pagination côté client.
        """
        return (
            db.query(Message).filter(Message.conversation_id == conversation_id).count()
        )
