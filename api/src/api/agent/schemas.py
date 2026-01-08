"""Schémas Pydantic pour les endpoints de l'agent."""

from uuid import UUID

from pydantic import BaseModel


class ChatRequest(BaseModel):
    """Requête de chat avec l'agent."""

    trip_id: UUID
    conversation_id: UUID
    message: str
    context_version: int | None = None


class ActionRequest(BaseModel):
    """Requête d'action rapide pour les widgets."""

    trip_id: UUID
    conversation_id: UUID
    action: dict  # {"type": "SELECT_FLIGHT" | "BOOK_FLIGHT" | "SELECT_HOTEL" | "BOOK_HOTEL", "offer_id": "..."}
    context_version: int | None = None


class SSEEvent(BaseModel):
    """Événement SSE (pour documentation, le format réel est string)."""

    event: str  # "message.delta", "message.final", "context.updated", "tool.start", "tool.end", "error"
    data: dict
