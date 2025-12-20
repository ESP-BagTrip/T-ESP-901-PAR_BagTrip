"""Schémas Pydantic pour les offres d'hôtels."""

from uuid import UUID

from pydantic import BaseModel


class HotelOfferResponse(BaseModel):
    """Réponse d'une offre d'hôtel selon PLAN.md."""

    id: UUID
    offer: dict  # offer_json complet
