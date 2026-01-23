"""Routes pour la réservation de vols."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.api.auth.middleware import get_current_user
from src.api.booking.schemas import (
    BookingResponse,
    FlightBookingRequest,
    FlightPriceRequest,
)
from src.config.database import get_db
from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightPriceResponse
from src.models.booking import Booking
from src.models.user import User
from src.utils.logger import LogLevel, logger

router = APIRouter(prefix="/v1/booking", tags=["Booking (Deprecated)"])


@router.post(
    "/pricing",
    summary="[DEPRECATED] Confirm flight price",
    description=(
        "**⚠️ DEPRECATED:** This endpoint is deprecated. "
        "Use `/v1/trips/{tripId}/flights/offers/{offerDbId}/price` instead.\n\n"
        "Verify and update the price of a selected flight offer.\n\n"
        "**Important:** You must first call `/v1/travel/flight/offers` to search for flights, "
        "then select a flight offer from the response and pass it here.\n\n"
        "The request body should contain a `flightOffer` object from the flight offers search response. "
        "This endpoint will confirm the current price and availability of the selected flight offer."
    ),
    deprecated=True,
    response_model=FlightPriceResponse,
    responses={
        200: {
            "description": "Price confirmation successful",
        },
        400: {"description": "Bad request - Invalid flight offer"},
        500: {"description": "Internal server error"},
    },
)
async def confirm_price(request: FlightPriceRequest):
    """
    Confirmer le prix d'un vol.

    Cette étape est nécessaire avant de créer une commande pour s'assurer
    que le prix est toujours valide.

    **Workflow:**
    1. Appeler `/api/travel/flight/offers` pour rechercher des vols
    2. Sélectionner une offre de vol (`flightOffer`) dans la réponse
    3. Passer cette offre ici pour confirmer le prix

    **Example request body:**
    ```json
    {
      "flightOffer": {
        "type": "flight-offer",
        "id": "1",
        "source": "GDS",
        "instantTicketingRequired": false,
        "nonHomogeneous": false,
        "oneWay": false,
        "itineraries": [...],
        "price": {...},
        "pricingOptions": {...},
        "validatingAirlineCodes": [...],
        "travelerPricings": [...]
      }
    }
    ```
    """
    try:
        return await amadeus_client.confirm_flight_price(request.flightOffer)
    except Exception as e:
        # Logger l'erreur avec traceback complète en mode debug
        if logger.level == LogLevel.DEBUG:
            logger.error(
                f"Price confirmation failed: {type(e).__name__}",
                {"error": str(e), "endpoint": "/api/booking/pricing"},
                exc_info=True,
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Price confirmation failed: {str(e)}",
        ) from e


@router.post(
    "/create",
    summary="[DEPRECATED] Create flight booking",
    description=(
        "**⚠️ DEPRECATED:** This endpoint is deprecated. "
        "Use `/v1/trips/{tripId}/booking-intents` and `/v1/booking-intents/{intentId}/book` instead.\n\n"
        "Book a flight and store the reservation"
    ),
    response_model=BookingResponse,
    deprecated=True,
)
async def create_booking(
    request: FlightBookingRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Créer une réservation de vol.
    Crée une commande chez Amadeus et enregistre la réservation en base de données.
    Nécessite une authentification.
    """
    try:
        # 1. Créer la commande chez Amadeus
        order_response = await amadeus_client.create_flight_order(
            request.flightOffer, request.travelers
        )

        amadeus_order_data = order_response.data
        amadeus_order_id = amadeus_order_data.get("id")

        if not amadeus_order_id:
            raise Exception("No order ID received from Amadeus")

        # Extraire le prix total
        price_total = 0.0
        currency = "EUR"
        flight_offers = amadeus_order_data.get("flightOffers", [])
        if flight_offers:
            price_data = flight_offers[0].get("price", {})
            price_total = float(price_data.get("grandTotal", 0.0))
            currency = price_data.get("currency", "EUR")

        # 2. Enregistrer en base de données
        booking = Booking(
            user_id=current_user.id,
            amadeus_order_id=amadeus_order_id,
            flight_offers=flight_offers,
            status="CONFIRMED",
            price_total=price_total,
            currency=currency,
        )

        db.add(booking)
        db.commit()
        db.refresh(booking)

        return BookingResponse(
            id=str(booking.id),
            amadeusOrderId=(booking.amadeus_order_id),
            status=(booking.status),
            priceTotal=(booking.price_total),
            currency=(booking.currency),
            createdAt=(booking.created_at),
        )

    except Exception as e:
        db.rollback()
        # Logger l'erreur avec traceback complète en mode debug
        if logger.level == LogLevel.DEBUG:
            logger.error(
                f"Booking creation failed: {type(e).__name__}",
                {"error": str(e), "endpoint": "/api/booking/create"},
                exc_info=True,
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Booking creation failed: {str(e)}",
        ) from e


@router.get(
    "/list",
    summary="[DEPRECATED] List user bookings",
    description=(
        "**⚠️ DEPRECATED:** This endpoint is deprecated. "
        "Use `/v1/trips` to get trips with their booking intents instead.\n\n"
        "Get all bookings for the authenticated user"
    ),
    response_model=list[BookingResponse],
    deprecated=True,
)
async def list_bookings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lister les réservations de l'utilisateur connecté.
    """
    bookings = (
        db.query(Booking)
        .filter(Booking.user_id == current_user.id)
        .order_by(Booking.created_at.desc())
        .all()
    )

    return [
        BookingResponse(
            id=str(booking.id),
            amadeusOrderId=booking.amadeus_order_id,
            status=booking.status,
            priceTotal=booking.price_total,
            currency=booking.currency,
            createdAt=booking.created_at,
        )
        for booking in bookings
    ]
