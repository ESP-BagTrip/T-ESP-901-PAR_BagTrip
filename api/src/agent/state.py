"""Définition de l'état de l'agent."""

from langgraph.graph import MessagesState


class AgentState(MessagesState):
    """
    État de l'agent étendant l'état standard de messages.
    Ajoute l'ID utilisateur pour le contexte.
    """

    userid: str
