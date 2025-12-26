"""Schémas Pydantic pour les booking intents."""

from uuid import UUID

from pydantic import BaseModel


class BookingIntentCreateRequest(BaseModel):
    """Requête de création de booking intent selon PLAN.md."""

    type: str  # flight | hotel
    flightOfferId: UUID | None = None
    hotelOfferId: UUID | None = None


class BookingIntentResponse(BaseModel):
    """Réponse booking intent selon PLAN.md."""

    id: UUID
    type: str
    status: str
    amount: float
    currency: str
    selectedOfferId: UUID | None


class BookingIntentBookRequestFlight(BaseModel):
    """Requête de booking pour un vol selon PLAN.md."""

    travelerIds: list[UUID]
    contacts: list[dict]


class BookingIntentBookRequestHotel(BaseModel):
    """Requête de booking pour un hôtel selon PLAN.md."""

    guests: list[dict]
    roomAssociations: list[dict] | None = None


class BookingIntentBookResponse(BaseModel):
    """Réponse de booking selon PLAN.md."""

    bookingIntent: dict
    amadeus: dict
