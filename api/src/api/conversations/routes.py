"""Routes pour les conversations."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.auth.trip_access import TripAccess, get_trip_access, get_trip_owner_access
from src.api.conversations.schemas import (
    ConversationCreateRequest,
    ConversationDetailResponse,
    ConversationListResponse,
    ConversationResponse,
)
from src.config.database import get_db
from src.models.conversation import Conversation
from src.models.user import User
from src.services.conversation_service import ConversationService
from src.utils.errors import AppError, create_http_exception

# Router pour les endpoints scoped par trip
router = APIRouter(prefix="/v1/trips/{tripId}/conversations", tags=["Conversations"])

# Router pour les endpoints de détail de conversation
detail_router = APIRouter(prefix="/v1/conversations", tags=["Conversations"])


@router.post(
    "",
    response_model=ConversationDetailResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new conversation",
    description="Create a new conversation for a trip",
)
async def create_conversation(
    request: ConversationCreateRequest,
    access: TripAccess = Depends(get_trip_owner_access),
    db: Session = Depends(get_db),
):
    """Créer une nouvelle conversation pour un trip."""
    try:
        conversation = ConversationService.create_conversation(
            db=db,
            trip_id=access.trip.id,
            user_id=access.trip.user_id,
            title=request.title,
        )
        return ConversationDetailResponse(conversation=ConversationResponse.model_validate(conversation))
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "",
    response_model=ConversationListResponse,
    summary="List conversations for a trip",
    description="Get all conversations for a specific trip",
)
async def list_conversations(
    access: TripAccess = Depends(get_trip_access),
    db: Session = Depends(get_db),
):
    """Lister toutes les conversations d'un trip."""
    try:
        conversations = ConversationService.get_conversations_by_trip(
            db=db,
            trip_id=access.trip.id,
            user_id=access.trip.user_id,
        )
        return ConversationListResponse(
            items=[ConversationResponse.model_validate(c) for c in conversations]
        )
    except AppError as e:
        raise create_http_exception(e) from e


@detail_router.get(
    "/{conversationId}",
    response_model=ConversationDetailResponse,
    summary="Get conversation details",
    description="Get detailed information about a specific conversation",
)
async def get_conversation(
    conversationId: UUID = Path(..., description="Conversation ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Récupérer une conversation par ID."""
    try:
        conversation = db.query(Conversation).filter(Conversation.id == conversationId).first()
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation not found")
        if conversation.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Access denied")
        return ConversationDetailResponse(conversation=ConversationResponse.model_validate(conversation))
    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e
