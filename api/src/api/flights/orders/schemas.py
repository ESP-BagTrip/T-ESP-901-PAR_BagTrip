"""Schémas Pydantic pour les flight orders."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class FlightOrderResponse(BaseModel):
    """Réponse d'un flight order."""

    id: UUID
    status: str | None
    bookingReference: str | None
    paymentId: str | None = None
    ticketUrl: str | None = None
    createdAt: datetime
