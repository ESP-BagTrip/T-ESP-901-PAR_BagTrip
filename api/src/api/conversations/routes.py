"""Routes pour les conversations."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.conversations.schemas import (
    ConversationCreateRequest,
    ConversationDetailResponse,
    ConversationListResponse,
    ConversationResponse,
)
from src.config.database import get_db
from src.models.conversation import Conversation
from src.models.trip import Trip
from src.models.user import User
from src.services.conversation_service import ConversationService
from src.utils.errors import AppError, create_http_exception

# Router pour les endpoints scoped par trip
router = APIRouter(prefix="/v1/trips/{tripId}/conversations", tags=["Conversations"])

# Router pour les endpoints de détail de conversation
detail_router = APIRouter(prefix="/v1/conversations", tags=["Conversations"])


async def verify_trip_ownership(db: Session, trip_id: UUID, user_id: UUID) -> Trip:
    """Vérifie que le trip appartient à l'utilisateur."""
    trip = db.query(Trip).filter(Trip.id == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    if trip.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return trip


async def verify_conversation_ownership(
    db: Session, conversation_id: UUID, user_id: UUID
) -> Conversation:
    """Vérifie que la conversation appartient à l'utilisateur."""
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.user_id != user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    return conversation


@router.post(
    "",
    response_model=ConversationDetailResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new conversation",
    description="Create a new conversation for a trip",
)
async def create_conversation(
    request: ConversationCreateRequest,
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Créer une nouvelle conversation pour un trip.
    - Vérifier que le trip appartient à l'utilisateur (via ConversationService)
    - Créer la conversation avec ConversationService.create_conversation()
    - Retourner la conversation créée
    """
    try:
        # Vérifier ownership du trip
        await verify_trip_ownership(db, tripId, current_user.id)

        conversation = ConversationService.create_conversation(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
            title=request.title,
        )
        return ConversationDetailResponse(conversation=ConversationResponse.model_validate(conversation))
    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e


@router.get(
    "",
    response_model=ConversationListResponse,
    summary="List conversations for a trip",
    description="Get all conversations for a specific trip",
)
async def list_conversations(
    tripId: UUID = Path(..., description="Trip ID"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lister toutes les conversations d'un trip.
    - Vérifier que le trip appartient à l'utilisateur
    - Récupérer les conversations via ConversationService.get_conversations_by_trip()
    - Retourner la liste triée par created_at DESC
    """
    try:
        # Vérifier ownership du trip
        await verify_trip_ownership(db, tripId, current_user.id)

        conversations = ConversationService.get_conversations_by_trip(
            db=db,
            trip_id=tripId,
            user_id=current_user.id,
        )
        return ConversationListResponse(
            items=[ConversationResponse.model_validate(c) for c in conversations]
        )
    except HTTPException:
        raise
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
    """
    Récupérer une conversation par ID.
    - Vérifier que la conversation appartient à l'utilisateur
    - Récupérer via ConversationService.get_conversation_by_id()
    - Retourner la conversation ou 404 si non trouvée
    """
    try:
        # Vérifier ownership de la conversation
        conversation = await verify_conversation_ownership(db, conversationId, current_user.id)
        return ConversationDetailResponse(conversation=ConversationResponse.model_validate(conversation))
    except HTTPException:
        raise
    except AppError as e:
        raise create_http_exception(e) from e
