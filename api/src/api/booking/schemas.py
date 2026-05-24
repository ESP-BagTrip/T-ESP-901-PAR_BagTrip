"""Schémas Pydantic pour les routes booking."""

from datetime import datetime

from pydantic import BaseModel, Field

from src.integrations.amadeus.types import (
    FlightOffer,
    FlightOrderTraveler,
)


class FlightPriceRequest(BaseModel):
    """
    Requête de vérification de prix pour une offre de vol.

    **Note:** The `flightOffer` must be obtained from a previous call to
    `/api/travel/flight/offers`. Pass the complete flight offer object from
    the search response here to confirm its current price.

    **Example:**
    ```json
    {
      "flightOffer": {
        "type": "flight-offer",
        "id": "1",
        "source": "GDS",
        "instantTicketingRequired": false,
        "nonHomogeneous": false,
        "oneWay": false,
        "itineraries": [
          {
            "duration": "PT6H10M",
            "segments": [...]
          }
        ],
        "price": {
          "currency": "USD",
          "total": "300.00",
          "base": "250.00"
        },
        "pricingOptions": {
          "fareType": ["PUBLISHED"],
          "includedCheckedBagsOnly": true
        },
        "validatingAirlineCodes": ["AA"],
        "travelerPricings": [...]
      }
    }
    ```
    """

    flightOffer: FlightOffer = Field(
        ...,
        description=(
            "Complete flight offer object from `/api/travel/flight/offers` response. "
            "This should be a single flight offer item from the `data` array."
        ),
    )


class FlightBookingRequest(BaseModel):
    """Requête de création de réservation."""

    flightOffer: FlightOffer
    travelers: list[FlightOrderTraveler]


class BookingResponse(BaseModel):
    """Réponse de création de réservation."""

    id: str
    amadeusOrderId: str
    status: str
    priceTotal: float
    currency: str
    createdAt: datetime
