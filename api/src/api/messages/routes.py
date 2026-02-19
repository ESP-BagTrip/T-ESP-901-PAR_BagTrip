"""Routes pour les messages."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.conversations.routes import verify_conversation_ownership
from src.api.messages.schemas import MessageListResponse, MessageResponse
from src.config.database import get_db
from src.models.user import User
from src.services.message_service import MessageService
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/conversations/{conversationId}/messages", tags=["Messages"])


@router.get(
    "",
    response_model=MessageListResponse,
    summary="Get conversation messages",
    description="Get paginated list of messages for a conversation",
)
async def get_messages(
    conversationId: UUID = Path(..., description="Conversation ID"),
    limit: int = Query(default=20, ge=1, le=100, description="Number of messages to return"),
    offset: int = Query(default=0, ge=0, description="Number of messages to skip"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Récupérer l'historique des messages d'une conversation avec pagination.
    - Vérifier que la conversation appartient à l'utilisateur
    - Récupérer les messages via MessageService.get_messages_by_conversation()
    - Récupérer le total via MessageService.get_message_count_by_conversation()
    - Retourner la liste paginée triée par created_at ASC (chronologique)
    """
    try:
        # Vérifier ownership de la conversation
        await verify_conversation_ownership(db, conversationId, current_user.id)

        # Récupérer les messages avec pagination
        messages = MessageService.get_messages_by_conversation(
            db=db,
            conversation_id=conversationId,
            limit=limit,
            offset=offset,
        )

        # Récupérer le total pour la pagination
        total = MessageService.get_message_count_by_conversation(db=db, conversation_id=conversationId)

        return MessageListResponse(
            items=[MessageResponse.model_validate(m) for m in messages],
            total=total,
            limit=limit,
            offset=offset,
        )
    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e
