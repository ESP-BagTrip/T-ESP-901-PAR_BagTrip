"""Recherche d'hôtels Amadeus — discovery only, no booking."""

import httpx

from src.config.env import settings
from src.integrations.amadeus.errors import raise_amadeus_connection_error, raise_for_amadeus_status
from src.integrations.amadeus.retry import amadeus_retry
from src.integrations.http_client import get_http_client
from src.utils.logger import logger

from .auth import fetch_token
from .types import (
    HotelListItem,
    HotelListResponse,
    HotelListSearchQuery,
    HotelOffer,
    HotelOfferResult,
    HotelOffersResponse,
    HotelOffersSearchQuery,
)


@amadeus_retry
async def search_hotel_list(query: HotelListSearchQuery) -> HotelListResponse:
    """
    Appel Hotel List: GET /v1/reference-data/locations/hotels/by-city
    Recherche d'hôtels par ville.
    """
    logger.debug("Starting hotel list search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/reference-data/locations/hotels/by-city"

    params: dict = {
        "cityCode": query.cityCode,
    }

    if query.radius is not None:
        params["radius"] = query.radius
    if query.radiusUnit:
        params["radiusUnit"] = query.radiusUnit
    if query.ratings:
        params["ratings"] = query.ratings
    if query.hotelSource:
        params["hotelSource"] = query.hotelSource

    try:
        logger.info("Making Amadeus hotel list search request", {"url": url, "params": params})

        client = get_http_client()
        response = await client.get(
            url,
            headers={"Authorization": f"Bearer {token}"},
            params=params,
            timeout=15.0,
        )

        logger.debug(
            "Amadeus hotel list search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "dataCount": len(response.json().get("data", []))
                if response.status_code == 200
                else 0,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus hotel list search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise_for_amadeus_status(response, "hotel list search")

        data = response.json()

        hotels = [HotelListItem(**hotel) for hotel in data.get("data", [])]

        response_obj = HotelListResponse(data=hotels)

        logger.info(
            "Hotel list search completed successfully", {"hotelsCount": len(response_obj.data)}
        )
        return response_obj

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel list search failed",
            {
                "message": str(error),
            },
        )
        raise_amadeus_connection_error(error, "hotel list search")


@amadeus_retry
async def search_hotel_offers(query: HotelOffersSearchQuery) -> HotelOffersResponse:
    """
    Appel Hotel Offers: GET /v3/shopping/hotel-offers
    Recherche d'offres d'hôtels avec prix.
    """
    logger.debug("Starting hotel offers search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v3/shopping/hotel-offers"

    params: dict = {
        "hotelIds": query.hotelIds,
    }

    if query.adults is not None:
        params["adults"] = query.adults
    if query.checkInDate:
        params["checkInDate"] = query.checkInDate
    if query.checkOutDate:
        params["checkOutDate"] = query.checkOutDate
    if query.currency:
        params["currency"] = query.currency

    try:
        logger.info("Making Amadeus hotel offers search request", {"url": url, "params": params})

        client = get_http_client()
        response = await client.get(
            url,
            headers={"Authorization": f"Bearer {token}"},
            params=params,
            timeout=20.0,
        )

        logger.debug(
            "Amadeus hotel offers search response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
                "dataCount": len(response.json().get("data", []))
                if response.status_code == 200
                else 0,
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
            raise_for_amadeus_status(response, "hotel offers search")

        data = response.json()

        results = []
        for item in data.get("data", []):
            hotel_data = item.get("hotel", {})
            offers_data = item.get("offers", [])
            offers = [HotelOffer(**o) for o in offers_data]
            results.append(
                HotelOfferResult(
                    type=item.get("type", "hotel-offers"),
                    hotel=hotel_data,
                    available=item.get("available", True),
                    offers=offers,
                )
            )

        response_obj = HotelOffersResponse(data=results)

        logger.info(
            "Hotel offers search completed successfully",
            {"resultsCount": len(response_obj.data)},
        )
        return response_obj

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus hotel offers search failed",
            {
                "message": str(error),
            },
        )
        raise_amadeus_connection_error(error, "hotel offers search")
