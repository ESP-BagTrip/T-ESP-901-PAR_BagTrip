"""Real flight search tool via Amadeus."""

from __future__ import annotations

from src.agent.tools._shared import _amadeus_semaphore
from src.integrations.amadeus.client import amadeus_client
from src.integrations.amadeus.types import FlightOfferSearchQuery
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


async def search_real_flights(
    origin: str,
    destination: str,
    date: str,
    return_date: str | None = None,
    adults: int = 1,
) -> dict:
    """Search real flight prices via Amadeus.

    Returns: {"flights": [...], "cheapest": <price>, "currency": "EUR"}
    """
    cache_key_params = {
        "origin": origin,
        "destination": destination,
        "date": date,
        "return_date": return_date,
        "adults": adults,
    }
    cached = idempotency_cache.get("search_real_flights", cache_key_params)
    if cached is not None:
        return cached

    try:
        async with _amadeus_semaphore:
            response = await amadeus_client.search_flight_offers(
                FlightOfferSearchQuery(
                    originLocationCode=origin,
                    destinationLocationCode=destination,
                    departureDate=date,
                    adults=adults,
                    returnDate=return_date,
                    max=5,
                    currencyCode="EUR",
                )
            )

        carriers = {}
        if response.dictionaries and response.dictionaries.carriers:
            carriers = response.dictionaries.carriers

        flights = []
        for offer in response.data[:5]:
            seg = offer.itineraries[0].segments[0] if offer.itineraries else None
            carrier_code = offer.validatingAirlineCodes[0] if offer.validatingAirlineCodes else "??"
            flight_data = {
                "airline": carrier_code,
                "airline_name": carriers.get(carrier_code, carrier_code),
                "flight_number": f"{seg.carrierCode} {seg.number}" if seg else "",
                "price": float(offer.price.grandTotal),
                "currency": offer.price.currency,
                "departure": seg.departure.at if seg else "",
                "arrival": seg.arrival.at if seg else "",
                "duration": offer.itineraries[0].duration if offer.itineraries else "",
            }
            # Return leg data (round-trip)
            if len(offer.itineraries) > 1:
                ret_seg = offer.itineraries[1].segments[0]
                flight_data["return_departure"] = ret_seg.departure.at
                flight_data["return_arrival"] = ret_seg.arrival.at
                flight_data["return_duration"] = offer.itineraries[1].duration or ""

            flights.append(flight_data)

        cheapest = min((f["price"] for f in flights), default=0)
        result = {
            "flights": flights,
            "cheapest": cheapest,
            "currency": "EUR",
            "source": "amadeus",
        }
        idempotency_cache.set("search_real_flights", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("search_real_flights failed", {"error": str(e)})
        return {"error": f"Amadeus flight search failed: {e}", "source": "error"}


FLIGHT_TOOLS: dict[str, dict] = {
    "search_real_flights": {
        "fn": search_real_flights,
        "description": 'Search real flight prices via Amadeus. Input: {"origin": "CDG", "destination": "BCN", "date": "2025-07-01", "return_date": "2025-07-08", "adults": 1}',
        "parameters": {
            "origin": "string (required) — origin IATA code",
            "destination": "string (required) — destination IATA code",
            "date": "string (required) — departure date YYYY-MM-DD",
            "return_date": "string (optional) — return date YYYY-MM-DD",
            "adults": "int (optional, default 1)",
        },
    },
}
