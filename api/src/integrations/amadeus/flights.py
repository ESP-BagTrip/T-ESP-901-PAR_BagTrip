"""Recherche de vols Amadeus."""

import httpx

from src.config.env import settings
from src.utils.logger import logger

from .auth import fetch_token
from .types import (
    FlightCheapestDateSearchQuery,
    FlightDateResponse,
    FlightDestinationResponse,
    FlightInspirationSearchQuery,
    FlightOfferResponse,
    FlightOfferSearchQuery,
)


async def search_flight_offers(query: FlightOfferSearchQuery) -> FlightOfferResponse:
    """
    Appel Shopping Flight Offers: GET /v2/shopping/flight-offers
    Recherche d'offres de vols.
    """
    logger.debug("Starting flight offers search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v2/shopping/flight-offers"

    # Construire les paramètres
    params = {
        "originLocationCode": query.originLocationCode,
        "destinationLocationCode": query.destinationLocationCode,
        "departureDate": query.departureDate,
        "adults": query.adults,
    }

    # Ajouter les paramètres optionnels
    if query.returnDate:
        params["returnDate"] = query.returnDate
    if query.children is not None:
        params["children"] = query.children
    if query.infants is not None:
        params["infants"] = query.infants
    if query.travelClass:
        params["travelClass"] = query.travelClass
    if query.nonStop is not None:
        params["nonStop"] = query.nonStop
    if query.currencyCode:
        params["currencyCode"] = query.currencyCode
    if query.maxPrice is not None:
        params["maxPrice"] = query.maxPrice
    if query.max is not None:
        params["max"] = query.max
    if query.includedAirlineCodes:
        params["includedAirlineCodes"] = query.includedAirlineCodes
    if query.excludedAirlineCodes:
        params["excludedAirlineCodes"] = query.excludedAirlineCodes

    try:
        logger.info("Making Amadeus flight offers search request", {"url": url, "params": params})

        async with httpx.AsyncClient(
            timeout=20.0
        ) as client:  # 20 seconds for complex flight offers queries
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        logger.debug(
            "Amadeus flight offers search response",
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
                "Amadeus flight offers search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus flight offers search failed: {response.status_code}")

        data = response.json()

        # Construire la réponse avec les types Pydantic
        from .types import FlightOffer, FlightOfferMeta, FlightOfferMetaLinks

        meta_data = data.get("meta")
        if meta_data:
            meta = FlightOfferMeta(
                count=meta_data.get("count", len(data.get("data", []))),
                links=FlightOfferMetaLinks(self_=meta_data.get("links", {}).get("self", url)),
            )
        else:
            meta = FlightOfferMeta(
                count=len(data.get("data", [])),
                links=FlightOfferMetaLinks(self_=url),
            )

        response_obj = FlightOfferResponse(
            meta=meta,
            data=[FlightOffer(**offer) for offer in data.get("data", [])],
            dictionaries=data.get("dictionaries"),
        )

        logger.info(
            "Flight offers search completed successfully", {"offersCount": len(response_obj.data)}
        )
        return response_obj

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus flight offers search failed",
            {
                "message": str(error),
            },
        )
        raise Exception(f"Amadeus flight offers search failed: {str(error)}") from error


async def search_flight_destinations(
    query: FlightInspirationSearchQuery,
) -> FlightDestinationResponse:
    """
    Appel Shopping Flight Destinations: GET /v1/shopping/flight-destinations
    Recherche de destinations inspirantes à partir d'un aéroport d'origine.
    """
    logger.debug("Starting flight destinations search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/shopping/flight-destinations"

    params = {
        "origin": query.origin,
    }

    # Ajouter les paramètres optionnels
    if query.departureDate:
        params["departureDate"] = query.departureDate
    if query.oneWay is not None:
        params["oneWay"] = query.oneWay
    if query.duration is not None:
        params["duration"] = query.duration
    if query.nonStop is not None:
        params["nonStop"] = query.nonStop
    if query.maxPrice is not None:
        params["maxPrice"] = query.maxPrice
    if query.viewBy:
        params["viewBy"] = query.viewBy

    try:
        logger.info(
            "Making Amadeus flight destinations search request", {"url": url, "params": params}
        )

        async with httpx.AsyncClient(timeout=15.0) as client:  # 15 seconds timeout
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        logger.debug(
            "Amadeus flight destinations search response",
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
                "Amadeus flight destinations search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus flight destinations search failed: {response.status_code}")

        data = response.json()

        # Construire la réponse avec les types Pydantic
        from .types import FlightDestination, FlightDestinationMeta, FlightDestinationMetaLinks

        meta_data = data.get("meta")
        if meta_data:
            meta = FlightDestinationMeta(
                currency=meta_data.get("currency", "EUR"),
                links=FlightDestinationMetaLinks(
                    self_=meta_data.get("links", {}).get("self") if meta_data.get("links") else None
                )
                if meta_data.get("links")
                else None,
            )
        else:
            meta = FlightDestinationMeta(
                currency="EUR",
                links=FlightDestinationMetaLinks(self_=url),
            )

        response_obj = FlightDestinationResponse(
            meta=meta,
            data=[FlightDestination(**dest) for dest in data.get("data", [])],
        )

        logger.info(
            "Flight destinations search completed successfully",
            {"destinationsCount": len(response_obj.data)},
        )
        return response_obj

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus flight destinations search failed",
            {
                "message": str(error),
            },
        )
        raise Exception(f"Amadeus flight destinations search failed: {str(error)}") from error


async def search_flight_cheapest_dates(query: FlightCheapestDateSearchQuery) -> FlightDateResponse:
    """
    Appel Shopping Flight Dates: GET /v1/shopping/flight-dates
    Recherche des dates les moins chères pour un trajet.
    """
    logger.debug("Starting flight cheapest dates search", {"query": query.model_dump()})
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/shopping/flight-dates"

    params = {
        "origin": query.origin,
        "destination": query.destination,
    }

    # Ajouter les paramètres optionnels
    if query.departureDate:
        params["departureDate"] = query.departureDate
    if query.oneWay is not None:
        params["oneWay"] = query.oneWay
    if query.duration is not None:
        params["duration"] = query.duration
    if query.nonStop is not None:
        params["nonStop"] = query.nonStop
    if query.maxPrice is not None:
        params["maxPrice"] = query.maxPrice
    if query.viewBy:
        params["viewBy"] = query.viewBy

    try:
        logger.info(
            "Making Amadeus flight cheapest dates search request", {"url": url, "params": params}
        )

        async with httpx.AsyncClient(timeout=15.0) as client:  # 15 seconds timeout
            response = await client.get(
                url,
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )

        logger.debug(
            "Amadeus flight cheapest dates search response",
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
                "Amadeus flight cheapest dates search failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            raise Exception(f"Amadeus flight cheapest dates search failed: {response.status_code}")

        data = response.json()

        # Construire la réponse avec les types Pydantic
        from .types import FlightDate, FlightDateMeta, FlightDateMetaLinks

        meta_data = data.get("meta")
        if meta_data:
            meta = FlightDateMeta(
                currency=meta_data.get("currency", "EUR"),
                links=FlightDateMetaLinks(
                    self_=meta_data.get("links", {}).get("self") if meta_data.get("links") else None
                )
                if meta_data.get("links")
                else None,
            )
        else:
            meta = FlightDateMeta(
                currency="EUR",
                links=FlightDateMetaLinks(self_=url),
            )

        response_obj = FlightDateResponse(
            meta=meta,
            data=[FlightDate(**date) for date in data.get("data", [])],
        )

        logger.info(
            "Flight cheapest dates search completed successfully",
            {"datesCount": len(response_obj.data)},
        )
        return response_obj

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus flight cheapest dates search failed",
            {
                "message": str(error),
            },
        )
        raise Exception(f"Amadeus flight cheapest dates search failed: {str(error)}") from error
