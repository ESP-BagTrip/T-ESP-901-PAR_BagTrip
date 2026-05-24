"""Schémas Pydantic pour les offres de vols."""

from uuid import UUID

from pydantic import BaseModel


class FlightOfferResponse(BaseModel):
    """Réponse d'une offre de vol selon PLAN.md."""

    id: UUID
    offer: dict  # offer_json complet


class FlightOfferPriceResponse(BaseModel):
    """Réponse de pricing d'une offre selon PLAN.md."""

    offerId: UUID
    pricedOffer: dict  # priced_offer_json
