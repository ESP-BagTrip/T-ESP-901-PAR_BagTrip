"""Real hotel search tool via Amadeus."""

from __future__ import annotations

from src.agent.tools._shared import _amadeus_semaphore
from src.integrations.amadeus.client import amadeus_client
from src.integrations.amadeus.types import (
    HotelListSearchQuery,
    HotelOffersSearchQuery,
)
from src.utils.idempotency import idempotency_cache
from src.utils.logger import logger


async def search_real_hotels(
    city_code: str,
    check_in: str,
    check_out: str,
    adults: int = 1,
) -> dict:
    """Search real hotel prices via Amadeus.

    Returns: {"hotels": [...], "source": "amadeus"}
    """
    cache_key_params = {
        "city_code": city_code,
        "check_in": check_in,
        "check_out": check_out,
        "adults": adults,
    }
    cached = idempotency_cache.get("search_real_hotels", cache_key_params)
    if cached is not None:
        return cached

    try:
        # Step 1: Get hotel list for the city
        async with _amadeus_semaphore:
            hotel_list = await amadeus_client.search_hotel_list(
                HotelListSearchQuery(cityCode=city_code, ratings="3,4,5")
            )

        if not hotel_list.data:
            return {"hotels": [], "source": "amadeus", "note": "No hotels found"}

        # Take first 10 hotel IDs for offers search
        hotel_ids = [h.hotelId for h in hotel_list.data[:10]]

        # Step 2: Get offers for those hotels
        async with _amadeus_semaphore:
            offers_response = await amadeus_client.search_hotel_offers(
                HotelOffersSearchQuery(
                    hotelIds=",".join(hotel_ids),
                    adults=adults,
                    checkInDate=check_in,
                    checkOutDate=check_out,
                    currency="EUR",
                )
            )

        hotels = []
        for item in offers_response.data:
            hotel_info = item.hotel
            if item.offers:
                offer = item.offers[0]
                price = float(offer.price.total) if offer.price and offer.price.total else None
                hotels.append(
                    {
                        "name": hotel_info.get("name", "Unknown Hotel"),
                        "hotel_id": hotel_info.get("hotelId", ""),
                        "price_total": price,
                        "currency": offer.price.currency if offer.price else "EUR",
                        "check_in": offer.checkInDate,
                        "check_out": offer.checkOutDate,
                        "source": "amadeus",
                    }
                )

        result = {"hotels": hotels, "source": "amadeus"}
        idempotency_cache.set("search_real_hotels", cache_key_params, result)
        return result
    except Exception as e:
        logger.error("search_real_hotels failed", {"error": str(e)})
        return {"hotels": [], "source": "error", "error": str(e)}


HOTEL_TOOLS: dict[str, dict] = {
    "search_real_hotels": {
        "fn": search_real_hotels,
        "description": 'Search real hotel prices via Amadeus. Input: {"city_code": "PAR", "check_in": "2025-07-01", "check_out": "2025-07-08", "adults": 1}',
        "parameters": {
            "city_code": "string (required) — IATA city code",
            "check_in": "string (required) — YYYY-MM-DD",
            "check_out": "string (required) — YYYY-MM-DD",
            "adults": "int (optional, default 1)",
        },
    },
}
