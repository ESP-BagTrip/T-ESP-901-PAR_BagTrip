"""Définition de l'état de l'agent."""

from uuid import UUID

from langgraph.graph import MessagesState


class AgentState(MessagesState):
    """
    État de l'agent étendant l'état standard de messages.
    Ajoute l'ID utilisateur, trip, conversation et version de contexte.
    """

    userid: str
    trip_id: UUID | None = None
    conversation_id: UUID | None = None
    context_version: int | None = None
