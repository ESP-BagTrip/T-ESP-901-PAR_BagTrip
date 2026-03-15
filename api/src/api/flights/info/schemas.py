"""Schémas Pydantic pour les informations de vol AirLabs."""

from pydantic import BaseModel


class FlightInfoResponse(BaseModel):
    """Réponse info vol temps réel."""

    flightIata: str | None = None
    airlineIata: str | None = None
    airlineName: str | None = None
    status: str | None = None
    departureIata: str | None = None
    departureTerminal: str | None = None
    departureGate: str | None = None
    departureTime: str | None = None
    departureActual: str | None = None
    departureDelay: int | None = None
    arrivalIata: str | None = None
    arrivalTerminal: str | None = None
    arrivalGate: str | None = None
    arrivalTime: str | None = None
    arrivalActual: str | None = None
    arrivalDelay: int | None = None
