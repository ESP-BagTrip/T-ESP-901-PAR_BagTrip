"""Routes pour les informations de vol en temps réel."""

import re

from fastapi import APIRouter, Depends, Path

from src.api.auth.middleware import get_current_user
from src.api.flights.info.schemas import FlightInfoResponse
from src.config.env import settings
from src.integrations.airlabs.client import airlabs_client
from src.models.user import User
from src.utils.errors import AppError, create_http_exception

router = APIRouter(prefix="/v1/travel/flights", tags=["Flight Info"])

_IATA_FLIGHT_RE = re.compile(r"^[A-Z0-9]{2}\d{1,4}$")


@router.get(
    "/{flightNumber}/info",
    response_model=FlightInfoResponse,
    summary="Get live flight info",
    description="Lookup real-time flight information via AirLabs",
)
async def get_flight_info(
    flightNumber: str = Path(..., description="IATA flight number (e.g. AF1234)"),
    _user: User = Depends(get_current_user),
):
    """Récupérer les infos temps réel d'un vol."""
    if not settings.AIRLABS_API_KEY:
        raise create_http_exception(
            AppError("AIRLABS_NOT_CONFIGURED", 503, "Flight info service not configured")
        )

    code = flightNumber.upper().strip()
    if not _IATA_FLIGHT_RE.match(code):
        raise create_http_exception(
            AppError("INVALID_FLIGHT_NUMBER", 400, f"Invalid IATA flight number: {flightNumber}")
        )

    data = airlabs_client.lookup_flight(code)
    if not data:
        raise create_http_exception(
            AppError("FLIGHT_NOT_FOUND", 404, f"No flight info found for {code}")
        )

    return FlightInfoResponse(
        flightIata=data.get("flight_iata"),
        airlineIata=data.get("airline_iata"),
        airlineName=data.get("airline_name"),
        status=data.get("status"),
        departureIata=data.get("dep_iata"),
        departureTerminal=data.get("dep_terminal"),
        departureGate=data.get("dep_gate"),
        departureTime=data.get("dep_time"),
        departureActual=data.get("dep_actual"),
        departureDelay=data.get("dep_delayed"),
        arrivalIata=data.get("arr_iata"),
        arrivalTerminal=data.get("arr_terminal"),
        arrivalGate=data.get("arr_gate"),
        arrivalTime=data.get("arr_time"),
        arrivalActual=data.get("arr_actual"),
        arrivalDelay=data.get("arr_delayed"),
    )
