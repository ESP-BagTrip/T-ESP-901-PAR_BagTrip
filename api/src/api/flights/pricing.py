from fastapi import APIRouter, HTTPException
from src.integrations.amadeus import amadeus_client
from src.integrations.amadeus.types import FlightOffer, FlightPriceResponse

router = APIRouter(prefix="/v1/shopping/flight-offers", tags=["Flight Pricing"])

@router.post(
    "/pricing",
    response_model=FlightPriceResponse,
    summary="Confirm flight price",
    description="Confirm the price of a flight offer (stateless wrapper for Amadeus API)"
)
async def confirm_price(
    flight_offer_data: dict,
):
    """
    Confirm price for a flight offer.
    Accepts the raw flight offer JSON.
    """
    try:
        # Check if the input is wrapped in data/flightOffers or just the offer
        if "data" in flight_offer_data and "flightOffers" in flight_offer_data["data"]:
             offers = flight_offer_data["data"]["flightOffers"]
             if not offers:
                 raise HTTPException(status_code=400, detail="No flight offers provided")
             offer_json = offers[0]
        elif "flightOffers" in flight_offer_data:
             offers = flight_offer_data["flightOffers"]
             if not offers:
                 raise HTTPException(status_code=400, detail="No flight offers provided")
             offer_json = offers[0]
        else:
            # Assume it is a single flight offer object
            offer_json = flight_offer_data

        flight_offer = FlightOffer(**offer_json)
        return await amadeus_client.confirm_flight_price(flight_offer)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

