"""Recherche de vols Amadeus."""

import json

import httpx

from src.config.env import settings
from src.utils.logger import logger

from .auth import fetch_token
from .types import (
    FlightCheapestDateSearchQuery,
    FlightDateResponse,
    FlightDestinationResponse,
    FlightInspirationSearchQuery,
    FlightOffer,
    FlightOfferResponse,
    FlightOfferSearchQuery,
    FlightOrderCreateQuery,
    FlightOrderResponse,
    FlightOrderTraveler,
    FlightPriceQuery,
    FlightPriceResponse,
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

    # Amadeus doesn't allow both includedAirlineCodes and excludedAirlineCodes together
    # Priority: includedAirlineCodes takes precedence if both are provided
    if query.includedAirlineCodes and query.excludedAirlineCodes:
        logger.warning(
            "Both includedAirlineCodes and excludedAirlineCodes provided. "
            "Using includedAirlineCodes only (Amadeus restriction)",
            {
                "includedAirlineCodes": query.includedAirlineCodes,
                "excludedAirlineCodes": query.excludedAirlineCodes,
            },
        )
        params["includedAirlineCodes"] = query.includedAirlineCodes
    elif query.includedAirlineCodes:
        params["includedAirlineCodes"] = query.includedAirlineCodes
    elif query.excludedAirlineCodes:
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


async def confirm_flight_price(flight_offer: FlightOffer) -> FlightPriceResponse:
    """
    Appel Flight Offers Price: POST /v1/shopping/flight-offers/pricing
    Confirme le prix d'une offre de vol.
    """
    logger.debug("Starting flight price confirmation")
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/shopping/flight-offers/pricing"

    # Convert FlightOffer to dict preserving all fields from the original Amadeus response
    # Use mode='json' to ensure proper JSON serialization (numbers stay numbers, not strings)
    # Use by_alias=True to match Amadeus field naming (camelCase)
    # Don't exclude None values as Amadeus may need the complete original response
    flight_offer_json = flight_offer.model_dump_json(by_alias=True, exclude_none=False)
    flight_offer_dict = json.loads(flight_offer_json)

    body = FlightPriceQuery(
        data={"type": "flight-offers-pricing", "flightOffers": [flight_offer_dict]}
    )

    # Serialize the body using JSON mode to preserve proper types
    body_dict = json.loads(body.model_dump_json(by_alias=True, exclude_none=False))

    try:
        logger.info("Making Amadeus flight price confirmation request", {"url": url})
        logger.debug("Request body", {"body": body_dict})

        async with httpx.AsyncClient(timeout=20.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                json=body_dict,
            )

        logger.debug(
            "Amadeus flight price response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
            },
        )

        if response.status_code != 200:
            logger.error(
                "Amadeus flight price confirmation failed",
                {
                    "status": response.status_code,
                    "response": response.text,
                },
            )
            # Tenter de parser l'erreur pour plus de détails
            try:
                error_data = response.json()
                logger.error("Amadeus error details", {"errors": error_data.get("errors")})
            except Exception:
                pass
            raise Exception(f"Amadeus flight price confirmation failed: {response.status_code}")

        data = response.json()

        # Le format de réponse est similaire à FlightOfferResponse mais encapsulé dans 'data'
        # data['data']['flightOffers'] contient les offres mises à jour

        response_data = data.get("data", {})
        flight_offers_data = response_data.get("flightOffers", [])

        # Logique de parsing simplifiée : on s'attend à recevoir des flightOffers mis à jour
        # On réutilise les structures existantes

        updated_offers = [FlightOffer(**offer) for offer in flight_offers_data]

        return FlightPriceResponse(data={"flightOffers": updated_offers})

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus flight price confirmation failed",
            {
                "message": str(error),
            },
        )
        raise Exception(f"Amadeus flight price confirmation failed: {str(error)}") from error


async def create_flight_order(
    flight_offer: FlightOffer, travelers: list[FlightOrderTraveler]
) -> FlightOrderResponse:
    """
    Appel Flight Create Orders: POST /v1/booking/flight-orders
    Crée une commande de vol.
    """
    logger.debug("Starting flight order creation")
    token = await fetch_token()

    url = f"{settings.AMADEUS_BASE_URL}/v1/booking/flight-orders"

    body = FlightOrderCreateQuery(
        data={
            "type": "flight-order",
            "flightOffers": [flight_offer],
            "travelers": travelers,
        }
    ).model_dump(by_alias=True, exclude_none=True)

    try:
        logger.info(
            "Making Amadeus flight order creation request",
            {
                "url": url,
                "travelers_count": len(travelers),
                "body_keys": list(body.keys()) if isinstance(body, dict) else None,
            },
        )
        logger.debug("Amadeus flight order request body", {"body": body})

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                json=body,
            )

        logger.debug(
            "Amadeus flight order response",
            {
                "status": response.status_code,
                "statusText": response.reason_phrase,
            },
        )

        if response.status_code not in [200, 201]:
            error_message = f"Amadeus flight order creation failed: {response.status_code}"
            try:
                error_data = response.json()
                errors = error_data.get("errors", [])
                if errors:
                    error_details = []
                    for error in errors:
                        detail = error.get("detail", "")
                        source = error.get("source", {})
                        error_details.append(
                            f"{detail} (field: {source.get('pointer', 'unknown')})"
                        )
                    error_message = f"{error_message}. Errors: {'; '.join(error_details)}"
                logger.error(
                    "Amadeus flight order creation failed",
                    {
                        "status": response.status_code,
                        "errors": errors,
                        "response": response.text[:500],  # Limit response size
                    },
                )
            except Exception as e:
                logger.error(
                    "Amadeus flight order creation failed",
                    {
                        "status": response.status_code,
                        "response": response.text[:500],
                        "parse_error": str(e),
                    },
                )
            raise Exception(error_message)

        data = response.json()

        return FlightOrderResponse(data=data.get("data", {}))

    except httpx.HTTPError as error:
        logger.error(
            "Amadeus flight order creation failed",
            {
                "message": str(error),
            },
        )
        raise Exception(f"Amadeus flight order creation failed: {str(error)}") from error
