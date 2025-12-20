"""Recherche et réservation d'hôtels Amadeus."""

import httpx

from src.config.env import settings
from src.utils.logger import logger

from .auth import fetch_token


async def search_hotel_offers(
    city_code: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
    check_in: str | None = None,
    check_out: str | None = None,
    adults: int = 1,
    room_qty: int = 1,
    currency: str | None = None,
) -> dict:
    """
    Appel Hotel List: GET /v3/shopping/hotel-offers
    Recherche d'offres d'hôtels.
    """
    logger.debug(
        "Starting hotel offers search",
        {
            "city_code": city_code,
            "latitude": latitude,
            "longitude": longitude,
            "check_in": check_in,
            "check_out": check_out,
        },
    )
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v3/shopping/hotel-offers"

    # Construire les paramètres
    params = {
        "adults": adults,
        "roomQuantity": room_qty,
    }

    if city_code:
        params["cityCode"] = city_code
    elif latitude is not None and longitude is not None:
        params["latitude"] = latitude
        params["longitude"] = longitude
    else:
        raise ValueError("Either city_code or latitude/longitude must be provided")

    if check_in:
        params["checkInDate"] = check_in
    if check_out:
        params["checkOutDate"] = check_out
    if currency:
        params["currency"] = currency

    try:
        logger.info("Making Amadeus hotel offers search request", {"url": url, "params": params})

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        logger.debug(
            "Amadeus hotel offers search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus hotel offers search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus hotel offers search failed: {response.status_code}")

        data = response.json()
        logger.info(
            "Hotel offers search completed successfully",
            {"offers_count": len(data.get("data", []))},
        )

        return data

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel offers search HTTP error",
            {"error": str(error)},
            exc_info=True,
        )
        raise Exception(f"Amadeus hotel offers search failed: {str(error)}") from error


async def book_hotel(
    offer_id: str,
    hotel_id: str,
    guests: list[dict],
    payments: dict | None = None,
) -> dict:
    """
    Appel Hotel Booking: POST /v3/booking/hotel-bookings
    Réserve un hôtel.
    """
    logger.debug(
        "Starting hotel booking",
        {
            "offer_id": offer_id,
            "hotel_id": hotel_id,
        },
    )
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v3/booking/hotel-bookings"

    body = {
        "data": {
            "offerId": offer_id,
            "guests": guests,
        }
    }

    if payments:
        body["data"]["payments"] = payments

    try:
        logger.info("Making Amadeus hotel booking request", {"url": url})

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                json=body,
            )

        logger.debug(
            "Amadeus hotel booking response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
            },
        )

        if response.status_code not in [200, 201]:
            logger.error(
                "Amadeus hotel booking failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            try:
                error_data = response.json()
                logger.error("Amadeus error details", {"errors": error_data.get("errors")})
            except Exception:
                pass
            raise Exception(f"Amadeus hotel booking failed: {response.status_code}")

        data = response.json()
        logger.info("Hotel booking completed successfully")

        return data

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel booking HTTP error",
            {"error": str(error)},
            exc_info=True,
        )
        raise Exception(f"Amadeus hotel booking failed: {str(error)}") from error
